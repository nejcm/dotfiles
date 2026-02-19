# dotfiles

Personal dotfiles, tool configs, and setup scripts for Windows, Linux (Fedora, Omarchy/Arch), and development tooling.

## Structure

| Directory       | Description                                                                                                                                                                                                                            |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **windows/**    | Windows dev setup: PowerShell 7, Chocolatey, winget, bun, Node tools, registry tweaks. Run `.\windows\setup.ps1` as Admin from repo root. See [windows/README.md](windows/README.md).                                                  |
| **powerShell/** | PowerShell profile (e.g. `gff` alias). Installed by `windows/setup.ps1`.                                                                                                                                                               |
| **chocolatey/** | Chocolatey package list (`packages.txt`). See [chocolatey/README.md](chocolatey/README.md).                                                                                                                                            |
| **cursor/**     | Cursor/VSCode extensions list. See [cursor/README.md](cursor/README.md).                                                                                                                                                               |
| **vscode/**     | Global code snippets.                                                                                                                                                                                                                  |
| **reg/**        | Windows registry tweaks (e.g. PowerShell 7 context menu).                                                                                                                                                                              |
| **fedora/**     | Fedora backup/restore scripts and setup. See [fedora/README.md](fedora/README.md).                                                                                                                                                     |
| **omarchy/**    | Omarchy/Arch Linux: Hyprland, Ghostty, Cursor, Starship, yay packages, touchpad/limine configs. See [omarchy/README.md](omarchy/README.md).                                                                                            |
| **bash/**       | Bash config and scripts (e.g. `gff-all`).                                                                                                                                                                                              |
| **fish/**       | Fish shell config.                                                                                                                                                                                                                     |
| **ghostty/**    | Ghostty terminal config.                                                                                                                                                                                                               |
| **starship/**   | Starship prompt config.                                                                                                                                                                                                                |
| **zellij/**     | Zellij config.                                                                                                                                                                                                                         |
| **ulauncher/**  | ULauncher settings and shortcuts.                                                                                                                                                                                                      |
| **opencode/**   | OpenCode agent architecture (agents, skills, workflows, specs). Install via `opencode/install.ps1` (Windows) or `opencode/install.sh` (Unix). See [opencode/README.md](opencode/README.md) and [opencode/INDEX.md](opencode/INDEX.md). |
| **vm/**         | OpenCode “on-the-go” setup: run OpenCode on a cloud VM and connect from phone (Termius, Tailscale, mosh). See [vm/open_code_on_the_go_setup_guide.md](vm/open_code_on_the_go_setup_guide.md).                                          |

## Quick start

- **Windows (new machine):** From repo root, run PowerShell as Administrator: `.\windows\setup.ps1`. Then restart and sign in to apps as needed.
- **OpenCode:** Run `.\opencode\install.ps1` (Windows) or `./opencode/install.sh` (Unix) to copy agents, skills, and config into your OpenCode config directory.
- **Fedora backup/restore:** See [fedora/README.md](fedora/README.md) for `backup.sh` and `restore.sh`.
- **Omarchy/Arch:** Copy configs from `omarchy/` and follow [omarchy/README.md](omarchy/README.md) for packages and function-key setup.

## Notes

- Subfolders often have their own README with install/backup/usage details.
- No single bootstrap script for all platforms; use the setup that matches your OS and needs.
