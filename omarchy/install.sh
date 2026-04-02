#! /bin/bash

# Omarchy installation script

yay -S < pkg-list.txt

# Install encore
curl -fsSL https://encore.dev/install.sh | bash

# Install bun
curl -fsSL https://bun.sh/install | bash

# Install pnpm
curl -fsSL https://get.pnpm.io/install.sh | sh -

# Install opencode
curl -fsSL https://opencode.ai/install | bash

# Install claude code
curl -fsSL https://claude.ai/install.sh | bash
    
# Install openai codex
npm i -g @openai/codex


git config --global user.name "nejcm"
git config --global user.email nejcm@users.noreply.github.com