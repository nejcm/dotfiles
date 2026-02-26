import type { Plugin } from "@opencode-ai/plugin";

export const FormatOnWritePlugin: Plugin = async ({
  $,
  directory,
  worktree,
}) => {
  const cwd = worktree || directory;

  return {
    "tool.execute.after": async (input) => {
      if (input.tool !== "write" && input.tool !== "edit") {
        return;
      }

      // Best effort: format after file mutations, but never block the run.
      await $`bun run format`.quiet().nothrow().cwd(cwd);
    },
  };
};

export default FormatOnWritePlugin;
