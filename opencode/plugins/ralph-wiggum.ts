import { type Plugin, tool } from "@opencode-ai/plugin";
import * as fs from "node:fs/promises";
import * as path from "node:path";

interface RalphState {
  iteration: number;
  maxIterations: number;
  completionPromise: string | null;
  prompt: string;
}

const STATE_RELATIVE_PATH = path.join(".opencode", "ralph-loop.md");

async function readState(root: string): Promise<RalphState | null> {
  const statePath = path.join(root, STATE_RELATIVE_PATH);

  try {
    const content = await fs.readFile(statePath, "utf8");
    const match = content.match(/^---\s*([\s\S]*?)\s*---\s*([\s\S]*)$/);
    if (!match) return null;

    const frontmatter = match[1];
    const prompt = match[2].trim();

    let iteration = 1;
    let maxIterations = 0;
    let completionPromise: string | null = null;

    for (const line of frontmatter.split("\n")) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) continue;
      const [rawKey, ...rest] = trimmed.split(":");
      const key = rawKey.trim();
      const value = rest.join(":").trim();

      if (key === "iteration") {
        const n = Number.parseInt(value, 10);
        if (!Number.isNaN(n) && n >= 0) iteration = n;
      } else if (key === "max_iterations") {
        const n = Number.parseInt(value, 10);
        if (!Number.isNaN(n) && n >= 0) maxIterations = n;
      } else if (key === "completion_promise") {
        if (value === "null" || value === "") {
          completionPromise = null;
        } else {
          completionPromise = value.replace(/^"(.*)"$/, "$1");
        }
      }
    }

    return { iteration, maxIterations, completionPromise, prompt };
  } catch {
    return null;
  }
}

async function writeState(root: string, state: RalphState): Promise<void> {
  const statePath = path.join(root, STATE_RELATIVE_PATH);
  const dir = path.dirname(statePath);
  await fs.mkdir(dir, { recursive: true });

  const completion =
    state.completionPromise == null
      ? "null"
      : JSON.stringify(state.completionPromise);

  const body = [
    "---",
    `iteration: ${state.iteration}`,
    `max_iterations: ${state.maxIterations}`,
    `completion_promise: ${completion}`,
    "---",
    "",
    state.prompt.trim(),
    "",
  ].join("\n");

  await fs.writeFile(statePath, body, "utf8");
}

async function deleteState(root: string): Promise<void> {
  const statePath = path.join(root, STATE_RELATIVE_PATH);
  try {
    await fs.unlink(statePath);
  } catch {
    // Ignore missing file or unlink errors
  }
}

function extractPromiseText(output: string): string | null {
  const match = output.match(/<promise>([\s\S]*?)<\/promise>/i);
  if (!match) return null;
  return match[1].trim().replace(/\s+/g, " ");
}

function extractAssistantTextFromMessages(history: any[]): string {
  const assistantMessages = history.filter(
    (m) => m?.info?.role === "assistant",
  );
  const last = assistantMessages[assistantMessages.length - 1];
  if (!last) return "";

  const parts = last.parts ?? [];
  const texts: string[] = [];
  for (const part of parts) {
    if (part?.type === "text" && typeof part.text === "string") {
      texts.push(part.text);
    }
  }
  return texts.join("\n").trim();
}

// Prevent re-entrant handling for the same session.idle event.
const processingSessions = new Set<string>();

export const RalphWiggumPlugin: Plugin = async (ctx) => {
  const { client, directory, worktree } = ctx;
  const root = worktree || directory;

  return {
    event: async ({ event }) => {
      if (event.type !== "session.idle") return;

      const sessionID = (event as any).properties?.sessionID as
        | string
        | undefined;
      if (!sessionID) return;

      if (processingSessions.has(sessionID)) return;
      processingSessions.add(sessionID);

      try {
        const state = await readState(root);
        if (!state) return;

        // Enforce max iterations if configured
        if (state.maxIterations > 0 && state.iteration >= state.maxIterations) {
          await deleteState(root);
          await client.session.prompt({
            path: { id: sessionID },
            body: {
              parts: [
                {
                  type: "text",
                  text: `🛑 Ralph loop: Max iterations (${state.maxIterations}) reached. The loop has been stopped.`,
                },
              ],
            },
          });
          return;
        }

        // Fetch last assistant message text
        let lastAssistantText = "";
        try {
          const history: any = await client.session.messages({
            path: { id: sessionID },
          } as any);
          if (Array.isArray(history)) {
            lastAssistantText = extractAssistantTextFromMessages(history);
          }
        } catch {
          // If we can't read history, fail safe by stopping the loop
          await deleteState(root);
          return;
        }

        if (!lastAssistantText) {
          // No assistant output to inspect; stop the loop to avoid spinning
          await deleteState(root);
          return;
        }

        // Check completion promise if configured
        if (state.completionPromise) {
          const promiseText = extractPromiseText(lastAssistantText);
          if (promiseText && promiseText === state.completionPromise) {
            await deleteState(root);
            await client.session.prompt({
              path: { id: sessionID },
              body: {
                parts: [
                  {
                    type: "text",
                    text: `✅ Ralph loop: Detected completion promise "${state.completionPromise}". Loop has finished.`,
                  },
                ],
              },
            });
            return;
          }
        }

        // Not complete: increment iteration and re-issue the same prompt
        const nextIteration = state.iteration + 1;
        const updated: RalphState = {
          ...state,
          iteration: nextIteration,
        };
        await writeState(root, updated);

        const headerLines = [
          `🔄 Ralph iteration ${nextIteration}`,
          state.completionPromise
            ? `Completion promise: ${state.completionPromise} (ONLY output this inside <promise> tags when it is truly satisfied)`
            : "No completion promise set - loop runs until max iterations.",
          "",
        ];

        const body = `${headerLines.join("\n")}${state.prompt}`;

        await client.session.prompt({
          path: { id: sessionID },
          body: {
            parts: [
              {
                type: "text",
                text: body,
              },
            ],
          },
        });
      } finally {
        processingSessions.delete(sessionID);
      }
    },

    "experimental.session.compacting": async (_input, output) => {
      const state = await readState(root);
      if (!state) return;

      output.context.push(
        [
          "## Ralph Loop State",
          `Iteration: ${state.iteration}`,
          `Max iterations: ${state.maxIterations}`,
          state.completionPromise
            ? `Completion promise: ${state.completionPromise}`
            : "Completion promise: (none)",
        ].join("\n"),
      );
    },

    tool: {
      "ralph-loop": tool({
        description:
          "Start a Ralph Wiggum loop in the current session. Input syntax: PROMPT... [--max-iterations N] [--completion-promise TEXT].\n\nExamples:\n- Build a REST API for todos --max-iterations 50 --completion-promise DONE\n- Fix the auth bug --max-iterations 20\n\nThe same prompt will be re-issued on each iteration until the completion promise is detected or max iterations are reached.",
        args: {
          input: tool.schema
            .string()
            .describe(
              "Prompt and optional flags, e.g. `Build API --max-iterations 20 --completion-promise DONE`",
            ),
        },
        async execute(args, context): Promise<string> {
          const rootDir = context.worktree || context.directory;

          const { prompt, maxIterations, completionPromise } = parseInput(
            args.input,
          );

          const initialState: RalphState = {
            iteration: 1,
            maxIterations,
            completionPromise,
            prompt,
          };

          await writeState(rootDir, initialState);

          const safetyNote =
            maxIterations > 0
              ? `Max iterations: ${maxIterations}.`
              : "WARNING: No max iterations set (loop may run indefinitely).";

          return [
            "Ralph loop initialized for this session.",
            "",
            `Prompt: ${prompt}`,
            completionPromise
              ? `Completion promise: ${completionPromise}`
              : "Completion promise: (none)",
            safetyNote,
            "",
            "Work on the task now. When you become idle, the loop will re-issue this prompt until completion or max iterations.",
            'To stop early, run the "cancel-ralph" tool or delete `.opencode/ralph-loop.md`.',
          ].join("\n");
        },
      }),

      "cancel-ralph": tool({
        description:
          "Cancel the active Ralph Wiggum loop by removing its state file.",
        args: {},
        async execute(_args, context): Promise<string> {
          const rootDir = context.worktree || context.directory;
          const state = await readState(rootDir);

          if (!state) {
            return "No active Ralph loop found (no `.opencode/ralph-loop.md` state file).";
          }

          await deleteState(rootDir);

          return `Cancelled Ralph loop (was at iteration ${state.iteration}, max_iterations=${state.maxIterations}).`;
        },
      }),
    },
  };
};

function parseInput(input: string): {
  prompt: string;
  maxIterations: number;
  completionPromise: string | null;
} {
  const tokens =
    input.match(/"[^"]*"|'[^']*'|\\S+/g)?.map((t) => stripQuotes(t)) ?? [];

  let maxIterations = 0;
  let completionPromise: string | null = null;
  const promptParts: string[] = [];

  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i];
    if (token === "--max-iterations") {
      const next = tokens[i + 1];
      if (!next || next.startsWith("--")) {
        throw new Error(
          "Error: --max-iterations requires a numeric argument (e.g. --max-iterations 20).",
        );
      }
      const n = Number.parseInt(next, 10);
      if (Number.isNaN(n) || n < 0) {
        throw new Error(
          `Error: --max-iterations must be a non-negative integer, got: ${next}`,
        );
      }
      maxIterations = n;
      i++;
    } else if (token === "--completion-promise") {
      const next = tokens[i + 1];
      if (!next || next.startsWith("--")) {
        throw new Error(
          "Error: --completion-promise requires a text argument (e.g. --completion-promise DONE).",
        );
      }
      completionPromise = next;
      i++;
    } else {
      promptParts.push(token);
    }
  }

  const prompt = promptParts.join(" ").trim();
  if (!prompt) {
    throw new Error(
      "Error: No prompt provided. Include a task description before any flags.",
    );
  }

  return { prompt, maxIterations, completionPromise };
}

function stripQuotes(token: string): string {
  if (
    (token.startsWith('"') && token.endsWith('"')) ||
    (token.startsWith("'") && token.endsWith("'"))
  ) {
    return token.slice(1, -1);
  }
  return token;
}

export default RalphWiggumPlugin;

