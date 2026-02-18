# Backup

Backup script for creating a backup with all the data.

```shell
# make executable
chmod +x backup.sh
# run
sudo ./backup.sh
```

**What it backs up:**

- Personal data (Documents, Pictures, Videos, Music, Downloads, Desktop, Templates, Work)
- Configuration files (.config, .bashrc, .gitconfig, .vscode)
- Development environment (.npm, .yarn, .cursor, go/)
- Security keys (.gnupg, .pki)
- System files (/etc/hosts)
- GNOME Desktop settings (dconf)
- Package lists (Flatpak, NPM, pip, Docker, GNOME extensions)

### Important Notes:

1. Review the script before running it to ensure it meets your needs
2. External storage - Consider copying the backup to external storage or cloud backup
3. SSH keys - If you have SSH keys, you'll need to recreate them or back them up separately
4. Passwords - The script doesn't back up passwords; you'll need to remember or have them stored securely

### Additional Recommendations:

1. Test the backup by checking the contents of ~/backup after running the script
2. Create a bootable USB with the new Fedora version
3. Document any custom configurations not covered by the script
4. Consider using rsync for incremental backups if you run this multiple times

# Restore

### Key Features:

1. Safety Checks:
   - Verifies sudo privileges
   - Checks if backup directory exists
   - Asks for confirmation before proceeding
2. Smart Restoration:
   - Creates timestamped backups of existing files before overwriting
   - Uses helper functions for consistent file and directory restoration
   - Handles missing backup items gracefully
3. Restores All Backed-up Items:
   - Personal data (Documents, Pictures, Videos, etc.)
   - Configuration files (.config, .bashrc, .gitconfig, etc.)
   - Development tools (.npm, .yarn, .cursor, etc.)
   - System files (/etc/hosts)
   - GNOME Desktop settings (dconf)
4. Manual Steps Guidance:
   - Lists package files that need manual reinstallation
   - Provides commands for reinstalling Flatpak apps, NPM packages, pip packages, etc.
   - Shows locations of Docker images and GNOME extensions lists
5. Post-Restoration:
   - Sets proper file permissions
   - Provides clear next steps for the user

### Run script

> The script should be run from the same directory where backup.sh was executed (it looks for a backup/ subdirectory). It will safely restore all your backed-up files and settings while preserving existing files by creating timestamped backups.

```shell
# make executable
chmod +x restore.sh
# run
sudo ./restore.sh
```

## Useful commands

### Remove old kernels

```shell
# current kernel
uname -r
```

```shell
# list installed
dnf list installed kernel
```

```shell
# remove all except current
sudo dnf remove --oldinstallonly
# or remove specific version
sudo dnf remove kernel-6.0.11-300.fc36.x86_64
```

or

```shell
dnf-utils
```

```shell
# install dnf-utils (If Needed)
sudo dnf install dnf-plugins-core
```

```shell
# list old kernels
sudo package-cleanup --oldkernels --count=2
```

```shell
# remove old kernels
sudo package-cleanup --oldkernels --count=2 -y
```
