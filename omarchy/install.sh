<<<<<<< Updated upstream
#! /bin/bash

# Omarchy installation script

yay -S < yay-list.txt

sudo timedatectl set-local-rtc 1

git config --global credential.helper store

# Install encore
curl -fsSL https://encore.dev/install.sh | bash

# Install bun
curl -fsSL https://bun.sh/install | bash

# Install opencode
curl -fsSL https://opencode.ai/install | bash

# Install claude code
curl -fsSL https://claude.ai/install.sh | bash
    
# Install openai codex
=======
#! /bin/bash

# Omarchy installation script

yay -S < yay-list.txt

# Install encore
curl -fsSL https://encore.dev/install.sh | bash

# Install bun
curl -fsSL https://bun.sh/install | bash

# Install opencode
curl -fsSL https://opencode.ai/install | bash

# Install claude code
curl -fsSL https://claude.ai/install.sh | bash
    
# Install openai codex
>>>>>>> Stashed changes
npm i -g @openai/codex