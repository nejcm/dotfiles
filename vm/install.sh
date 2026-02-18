#!/usr/bin/env bash

# Update and install dependencies
sudo apt update && sudo apt -y upgrade
sudo apt -y install curl git unzip jq tmux

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Install OpenCode AI CLI
curl -fsSL https://opencode.ai/install | bash

# Install Mosh
sudo apt -y install mosh

# Login to OpenCode AI
opencode auth login

# Set up OneSignal notification plugin
mkdir -p ~/.config/opencode/plugins
cat > ~/.config/opencode/plugins/notify-question.js <<'EOF'
export const NtfyNotifyPlugin = async ({ project, $, directory }) => {
  const url = 'nejcm-2hy9uge4';
  const projectName = project?.name || "opencode";

  const send = async ({ title, priority, tags, message }) => {
    // ntfy supports headers like Title/Priority/Tags. :contentReference[oaicite:2]{index=2}
    const headers = [
      `-H`, `Title: ${title}`,
      `-H`, `Priority: ${priority}`,
      `-H`, `Tags: ${tags}`,
    ];

    await $`curl -fsS ${headers} -d ${message} ${url}`;
  };

  return {
    // 1) Notify when OpenCode asks a question (needs user input)
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "question") return; // tool hooks exist. :contentReference[oaicite:3]{index=3}

      // Best-effort: include args so you can see what it asked.
      const args = output?.args ? JSON.stringify(output.args) : "(no args)";
      await send({
        title: "OpenCode needs input",
        priority: "urgent",
        tags: "robot,question",
        message: `[${projectName}] ${directory}\n\n${args}`,
      });
    },

    // 2) Notify on session idle + session error
    event: async ({ event }) => {
      // OpenCode session events include session.idle and session.error. :contentReference[oaicite:4]{index=4}
      if (event.type === "session.idle") {
        await send({
          title: "OpenCode session idle",
          priority: "default",
          tags: "robot,check",
          message: `[${projectName}] Session is idle.\n${directory}`,
        });
      }

      if (event.type === "session.error") {
        await send({
          title: "OpenCode session error",
          priority: "urgent",
          tags: "robot,warning",
          message: `[${projectName}] Session error.\n${directory}\n\n${JSON.stringify(event)}`,
        });
      }
    },
  };
};
EOF