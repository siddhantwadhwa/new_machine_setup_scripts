# MacBook Development Environment Migration Tool

This project helps you migrate your development environment from one MacBook to another, ensuring a smooth transition with minimal manual setup.

## Overview

The migration tool consists of two main scripts:
1. `mac_dev_migration.sh` - Run this on your old MacBook to create a backup
2. `restore.sh` - Generated automatically and run on your new MacBook to restore settings

## Features

- **Shell Configuration**: Backs up and restores your `.bash_profile` and other shell files
- **iTerm2 Settings**: Preserves your terminal configuration and profiles
- **Vim Configuration**: Transfers your Vim settings and plugins
- **Git Settings**: Migrates your global Git configuration
- **Homebrew Packages**: Records and reinstalls your Homebrew packages
- **SSH Configuration**: Securely transfers your SSH setup (with manual key transfer)
- **Python/Conda Setup**: Migrates your Python environment, including Miniconda

## Requirements

- macOS on both source and destination machines
- Bash shell
- Internet connection (for downloading installers if needed)

## Usage Instructions

### Step 1: Backup Your Old MacBook

1. Download the script to your old MacBook:
   ```bash
   curl -o mac_dev_migration.sh https://raw.githubusercontent.com/yourusername/mac-dev-migration/main/mac_dev_migration.sh
   ```

2. Make the script executable:
   ```bash
   chmod +x mac_dev_migration.sh
   ```

3. Run the backup script:
   ```bash
   ./mac_dev_migration.sh
   ```

4. The script will create a backup directory at `~/mac_migration_backup_YYYYMMDD_HHMMSS`

### Step 2: Transfer the Backup to Your New MacBook

1. Copy the backup directory to your new MacBook using one of these methods:

   **Option A: Direct Transfer (if both Macs are available)**
   ```bash
   # On your new MacBook, from the Terminal
   scp -r old-mac-username@old-mac-ip-address:~/mac_migration_backup_* ~/
   ```

   **Option B: Using External Storage**
   - Copy the backup directory to an external drive
   - Connect the drive to your new MacBook and copy the directory

   **Option C: Using Cloud Storage**
   - Upload the backup directory to Google Drive, Dropbox, etc.
   - Download it on your new MacBook

### Step 3: Restore on Your New MacBook

1. Navigate to the backup directory:
   ```bash
   cd ~/mac_migration_backup_YYYYMMDD_HHMMSS
   ```

2. Run the restore script:
   ```bash
   ./restore.sh
   ```

3. Follow the interactive prompts to select what you want to restore:
   - Choose option 1 to restore everything
   - Or select specific components to restore individually

4. The script will guide you through the restoration process, including:
   - Installing Homebrew if needed
   - Setting up Miniconda if it was on your old system
   - Restoring your shell configuration
   - Installing your previous applications and tools

5. After the script completes, restart your terminal or applications for changes to take effect

## Troubleshooting

### Logs
- Backup log: `~/mac_migration_backup_YYYYMMDD_HHMMSS/migration.log`
- Restore log: `~/mac_migration_backup_YYYYMMDD_HHMMSS/restore.log`

### Common Issues

**Permission Denied**
```bash
chmod +x ~/mac_migration_backup_YYYYMMDD_HHMMSS/restore.sh
```

**Homebrew Installation Fails**
- Run the Homebrew installation manually:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
- Then continue with the restore script

**SSH Keys Not Working**
- SSH keys need to be manually transferred for security
- Use the helper script in the backup:
```bash
~/mac_migration_backup_YYYYMMDD_HHMMSS/.ssh/copy_ssh_keys.sh
```

**Python/Conda Environment Issues**
- If conda environments fail to restore:
```bash
# Manually create from the backup files
conda env create -f ~/mac_migration_backup_YYYYMMDD_HHMMSS/python/conda_envs/environment_name.yml
```

## Security Notes

- The backup does NOT automatically copy SSH private keys
- Review Git credentials before transferring
- Consider removing sensitive information from configuration files

## Customization

You can modify `mac_dev_migration.sh` to add or remove components based on your needs:

- To add a new component, create a new backup function and add it to the main backup process
- To skip a component, comment out its corresponding line in the main function

## License

This project is open source and available under the MIT License.

---

For more information or to report issues, please visit the project repository at:
https://github.com/yourusername/mac-dev-migration 