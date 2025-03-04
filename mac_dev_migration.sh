#!/bin/bash

# Mac Development Environment Migration Script
# This script helps migrate development settings from one Mac to another

# Set source and destination directories
SOURCE_DIR="$HOME"
BACKUP_DIR="$HOME/mac_migration_backup_$(date +%Y%m%d_%H%M%S)"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Log function
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$BACKUP_DIR/migration.log"
}

log "Starting Mac development environment migration backup"
log "Backup directory: $BACKUP_DIR"

# Function to backup a file or directory
backup_item() {
  local source="$1"
  local dest_dir="$2"
  
  if [ -e "$source" ]; then
    log "Backing up $source"
    mkdir -p "$(dirname "$dest_dir/$(basename "$source")")"
    cp -R "$source" "$dest_dir/"
  else
    log "Warning: $source does not exist, skipping"
  fi
}

# 1. Backup iTerm2 settings
backup_iterm() {
  log "Backing up iTerm2 settings"
  backup_item "$HOME/Library/Preferences/com.googlecode.iterm2.plist" "$BACKUP_DIR/iterm2"
  # Also backup custom profiles if they exist
  backup_item "$HOME/Library/Application Support/iTerm2" "$BACKUP_DIR/iterm2"
}

# 2. Backup Bash profile files
backup_bash_profiles() {
  log "Starting shell configuration files backup" "INFO"
  
  # Backup bash_profile which you confirmed exists
  backup_item "$HOME/.bash_profile" "$BACKUP_DIR" "Bash profile"
  
  # Check for other common shell config files without assuming they exist
  for shell_file in "$HOME"/.{bashrc,profile,zshrc,zprofile,zsh_history,bash_history}; do
    if [ -f "$shell_file" ]; then
      backup_item "$shell_file" "$BACKUP_DIR" "Shell configuration file"
    fi
  done
  
  # Since you have conda in your bash_profile, let's also backup conda config
  if [ -d "$HOME/.conda" ]; then
    backup_item "$HOME/.conda" "$BACKUP_DIR" "Conda configuration"
    log "Conda configuration backed up" "SUCCESS"
  fi
  
  # If you have a miniconda3 installation, we should note its location
  if [ -d "$HOME/opt/miniconda3" ]; then
    echo "$HOME/opt/miniconda3" > "$BACKUP_DIR/miniconda_path.txt"
    log "Miniconda path recorded" "SUCCESS"
  fi
  
  log "Shell configuration files backup completed" "INFO"
}

# 3. Backup Vim configuration
backup_vim() {
  log "Backing up Vim configuration"
  backup_item "$HOME/.vimrc" "$BACKUP_DIR"
  backup_item "$HOME/.vim" "$BACKUP_DIR"
}

# 4. Backup Git configuration
backup_git() {
  log "Backing up Git configuration"
  backup_item "$HOME/.gitconfig" "$BACKUP_DIR"
  backup_item "$HOME/.gitignore_global" "$BACKUP_DIR"
}

# 5. Backup Homebrew packages
backup_homebrew() {
  log "Backing up Homebrew packages list"
  if command -v brew &>/dev/null; then
    brew bundle dump --file="$BACKUP_DIR/Brewfile"
    brew list --formula > "$BACKUP_DIR/brew_formulas.txt"
    brew list --cask > "$BACKUP_DIR/brew_casks.txt"
  else
    log "Homebrew not installed, skipping"
  fi
}

# 6. Backup SSH keys and config
backup_ssh() {
  log "Backing up SSH configuration"
  if [ -d "$HOME/.ssh" ]; then
    mkdir -p "$BACKUP_DIR/.ssh"
    # Copy config but not the actual keys yet (for security)
    cp "$HOME/.ssh/config" "$BACKUP_DIR/.ssh/" 2>/dev/null || true
    
    # List keys but don't copy them automatically
    ls -la "$HOME/.ssh" > "$BACKUP_DIR/.ssh/keys_list.txt"
    log "SSH keys found. For security, keys are not automatically copied."
    log "Check $BACKUP_DIR/.ssh/keys_list.txt for a list of keys to manually transfer."
  else
    log "No SSH directory found, skipping"
  fi
}

# Add this new function to the backup script

backup_python_config() {
  log "Starting Python configuration backup" "INFO"
  
  # Check which Python versions are installed
  log "Checking Python installations" "INFO"
  
  # Create a directory for Python-related backups
  mkdir -p "$BACKUP_DIR/python"
  
  # Check for system Python and Python3
  if command -v python &>/dev/null; then
    python --version > "$BACKUP_DIR/python/system_python_version.txt" 2>&1
    which python > "$BACKUP_DIR/python/system_python_path.txt"
    log "System Python found and version recorded" "SUCCESS"
  fi
  
  if command -v python3 &>/dev/null; then
    python3 --version > "$BACKUP_DIR/python/system_python3_version.txt" 2>&1
    which python3 > "$BACKUP_DIR/python/system_python3_path.txt"
    log "System Python3 found and version recorded" "SUCCESS"
  fi
  
  # Check for pip installations
  if command -v pip &>/dev/null; then
    pip list --format=freeze > "$BACKUP_DIR/python/pip_packages.txt"
    log "Pip packages list backed up" "SUCCESS"
  fi
  
  if command -v pip3 &>/dev/null; then
    pip3 list --format=freeze > "$BACKUP_DIR/python/pip3_packages.txt"
    log "Pip3 packages list backed up" "SUCCESS"
  fi
  
  # Check for conda environments
  if command -v conda &>/dev/null; then
    conda env list > "$BACKUP_DIR/python/conda_environments.txt"
    log "Conda environments list backed up" "SUCCESS"
    
    # Export each conda environment
    log "Exporting conda environments (this may take a while)" "INFO"
    mkdir -p "$BACKUP_DIR/python/conda_envs"
    
    # Get list of environments (excluding base)
    conda_envs=$(conda env list | grep -v "^#" | grep -v "base" | awk '{print $1}')
    
    # Export base environment
    conda env export -n base > "$BACKUP_DIR/python/conda_envs/base.yml"
    log "Exported base conda environment" "SUCCESS"
    
    # Export other environments
    for env in $conda_envs; do
      if [ -n "$env" ]; then
        conda env export -n "$env" > "$BACKUP_DIR/python/conda_envs/${env}.yml"
        log "Exported conda environment: $env" "SUCCESS"
      fi
    done
  fi
  
  # Check for pyenv
  if command -v pyenv &>/dev/null; then
    pyenv versions > "$BACKUP_DIR/python/pyenv_versions.txt"
    pyenv global > "$BACKUP_DIR/python/pyenv_global.txt"
    backup_item "$HOME/.pyenv" "$BACKUP_DIR/python" "Pyenv directory"
    log "Pyenv configuration backed up" "SUCCESS"
  fi
  
  # Check for Python aliases in shell config
  grep -r "alias.*python" "$HOME"/.{bash_profile,bashrc,zshrc} 2>/dev/null > "$BACKUP_DIR/python/python_aliases.txt" || true
  
  # Check for virtualenv/venv directories
  find "$HOME" -name "venv" -o -name ".venv" -type d -maxdepth 3 > "$BACKUP_DIR/python/virtualenv_dirs.txt" 2>/dev/null || true
  
  log "Python configuration backup completed" "INFO"
}

# Run all backup functions
backup_iterm
backup_bash_profiles
backup_vim
backup_git
backup_homebrew
backup_ssh
backup_python_config

# Create a restore script
cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash

# Restore script for Mac development environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$HOME"

# Log function
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

log "Starting restoration of development environment"

# Function to restore a file or directory
restore_item() {
  local source="$1"
  local dest="$2"
  
  if [ -e "$source" ]; then
    log "Restoring $source to $dest"
    mkdir -p "$(dirname "$dest")"
    cp -R "$source" "$dest"
  else
    log "Warning: $source does not exist, skipping"
  fi
}

# Restore iTerm2 settings
restore_iterm() {
  log "Restoring iTerm2 settings"
  if [ -e "$SCRIPT_DIR/iterm2/com.googlecode.iterm2.plist" ]; then
    restore_item "$SCRIPT_DIR/iterm2/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/"
    log "iTerm2 settings restored. You may need to restart iTerm2."
  fi
  
  if [ -d "$SCRIPT_DIR/iterm2/iTerm2" ]; then
    restore_item "$SCRIPT_DIR/iterm2/iTerm2" "$HOME/Library/Application Support/"
  fi
}

# Restore Bash profile files
restore_bash_profiles() {
  log "Restoring Bash profile files"
  restore_item "$SCRIPT_DIR/.bash_profile" "$HOME/"
  restore_item "$SCRIPT_DIR/.bashrc" "$HOME/"
  restore_item "$SCRIPT_DIR/.bashrc_gpi" "$HOME/"
  restore_item "$SCRIPT_DIR/.profile" "$HOME/"
  restore_item "$SCRIPT_DIR/.zshrc" "$HOME/"
  
  log "Shell configuration files restored. You may need to restart your terminal."
}

# Restore Vim configuration
restore_vim() {
  log "Restoring Vim configuration"
  restore_item "$SCRIPT_DIR/.vimrc" "$HOME/"
  restore_item "$SCRIPT_DIR/.vim" "$HOME/"
}

# Restore Git configuration
restore_git() {
  log "Restoring Git configuration"
  restore_item "$SCRIPT_DIR/.gitconfig" "$HOME/"
  restore_item "$SCRIPT_DIR/.gitignore_global" "$HOME/"
}

# Restore Homebrew packages
restore_homebrew() {
  log "Restoring Homebrew packages"
  if command -v brew &>/dev/null; then
    if [ -f "$SCRIPT_DIR/Brewfile" ]; then
      log "Installing packages from Brewfile"
      brew bundle --file="$SCRIPT_DIR/Brewfile"
    else
      log "No Brewfile found, skipping"
    fi
  else
    log "Homebrew not installed. Please install it first:"
    log "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  fi
}

# Restore SSH config (but not keys)
restore_ssh() {
  log "Restoring SSH configuration"
  mkdir -p "$HOME/.ssh"
  if [ -f "$SCRIPT_DIR/.ssh/config" ]; then
    restore_item "$SCRIPT_DIR/.ssh/config" "$HOME/.ssh/"
    chmod 600 "$HOME/.ssh/config"
  fi
  
  log "SSH config restored. For security, SSH keys must be manually transferred."
  log "Check $SCRIPT_DIR/.ssh/keys_list.txt for a list of keys to transfer."
}

# Add this function to the restore script

restore_python_config() {
  log "Starting Python configuration restoration" "INFO"
  
  # Check if Python is installed on the new system
  if ! command -v python3 &>/dev/null; then
    log "Python 3 not found on this system" "WARNING"
    
    # Offer to install Python 3 via Homebrew
    read -p "Would you like to install Python 3 via Homebrew? (y/n): " install_python
    if [[ "$install_python" =~ ^[Yy]$ ]]; then
      if command -v brew &>/dev/null; then
        log "Installing Python 3 via Homebrew..." "INFO"
        brew install python || {
          log "Failed to install Python 3" "ERROR"
        }
      else
        log "Homebrew not installed. Please install Homebrew first." "ERROR"
      fi
    fi
  else
    log "Python 3 is already installed: $(python3 --version)" "SUCCESS"
  fi
  
  # Set up python -> python3 alias if it doesn't exist
  if command -v python3 &>/dev/null; then
    if ! command -v python &>/dev/null || [ "$(python --version 2>&1)" != "$(python3 --version 2>&1)" ]; then
      log "Setting up python -> python3 alias" "INFO"
      
      # Check which shell is being used
      current_shell=$(basename "$SHELL")
      
      if [ "$current_shell" = "bash" ]; then
        target_file="$HOME/.bash_profile"
      elif [ "$current_shell" = "zsh" ]; then
        target_file="$HOME/.zshrc"
      else
        target_file="$HOME/.bash_profile"  # Default to bash_profile
      fi
      
      # Add the alias if it doesn't already exist
      if ! grep -q "alias python=" "$target_file" 2>/dev/null; then
        echo -e "\n# Added by migration script - make python point to python3" >> "$target_file"
        echo "alias python=python3" >> "$target_file"
        echo "alias pip=pip3" >> "$target_file"
        log "Added python=python3 and pip=pip3 aliases to $target_file" "SUCCESS"
      else
        log "Python alias already exists in $target_file" "INFO"
      fi
    else
      log "Python already points to Python 3" "SUCCESS"
    fi
  fi
  
  # Restore conda environments if conda is installed
  if command -v conda &>/dev/null && [ -d "$SCRIPT_DIR/python/conda_envs" ]; then
    log "Restoring conda environments" "INFO"
    
    # Get list of environment files
    env_files=$(find "$SCRIPT_DIR/python/conda_envs" -name "*.yml")
    
    for env_file in $env_files; do
      env_name=$(basename "$env_file" .yml)
      
      # Skip base environment as it already exists
      if [ "$env_name" != "base" ]; then
        log "Creating conda environment: $env_name" "INFO"
        conda env create -f "$env_file" || {
          log "Failed to create conda environment: $env_name" "WARNING"
          log "You may need to create it manually" "WARNING"
        }
      else
        # For base environment, just install packages that might be missing
        log "Updating base conda environment" "INFO"
        conda env update -n base -f "$env_file" || {
          log "Failed to update base environment" "WARNING"
        }
      fi
    done
  fi
  
  # Install pip packages if needed
  if [ -f "$SCRIPT_DIR/python/pip3_packages.txt" ] && command -v pip3 &>/dev/null; then
    log "Would you like to install pip packages from your old system?" "INFO"
    log "Note: This could take a while and might cause conflicts with conda" "WARNING"
    
    read -p "Install pip packages? (y/n): " install_pip
    if [[ "$install_pip" =~ ^[Yy]$ ]]; then
      log "Installing pip packages..." "INFO"
      pip3 install -r "$SCRIPT_DIR/python/pip3_packages.txt" || {
        log "Some pip packages failed to install" "WARNING"
      }
    fi
  fi
  
  # Restore pyenv if it was backed up
  if [ -d "$SCRIPT_DIR/python/.pyenv" ] && ! command -v pyenv &>/dev/null; then
    log "Pyenv configuration found in backup" "INFO"
    log "Would you like to install pyenv?" "INFO"
    
    read -p "Install pyenv? (y/n): " install_pyenv
    if [[ "$install_pyenv" =~ ^[Yy]$ ]]; then
      if command -v brew &>/dev/null; then
        brew install pyenv || {
          log "Failed to install pyenv" "ERROR"
        }
      else
        log "Installing pyenv via curl..." "INFO"
        curl https://pyenv.run | bash || {
          log "Failed to install pyenv" "ERROR"
        }
      fi
      
      # Add pyenv to shell config if not already there
      current_shell=$(basename "$SHELL")
      if [ "$current_shell" = "bash" ]; then
        target_file="$HOME/.bash_profile"
      elif [ "$current_shell" = "zsh" ]; then
        target_file="$HOME/.zshrc"
      else
        target_file="$HOME/.bash_profile"  # Default to bash_profile
      fi
      
      if ! grep -q "pyenv init" "$target_file" 2>/dev/null; then
        echo -e "\n# Added by migration script - pyenv setup" >> "$target_file"
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$target_file"
        echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> "$target_file"
        echo 'eval "$(pyenv init --path)"' >> "$target_file"
        echo 'eval "$(pyenv init -)"' >> "$target_file"
        log "Added pyenv initialization to $target_file" "SUCCESS"
      fi
    fi
  fi
  
  log "Python configuration restoration completed" "INFO"
  log "You may need to restart your terminal for Python aliases to take effect" "INFO"
  return 0
}

# Menu to select what to restore
echo "What would you like to restore?"
echo "1. Everything"
echo "2. iTerm2 settings"
echo "3. Bash profile files"
echo "4. Vim configuration"
echo "5. Git configuration"
echo "6. Homebrew packages"
echo "7. SSH configuration"
echo "8. Python configuration"
echo "0. Exit"

read -p "Enter your choice (0-8): " choice

case $choice in
  1)
    restore_iterm
    restore_bash_profiles
    restore_vim
    restore_git
    restore_homebrew
    restore_ssh
    restore_python_config
    ;;
  2) restore_iterm ;;
  3) restore_bash_profiles ;;
  4) restore_vim ;;
  5) restore_git ;;
  6) restore_homebrew ;;
  7) restore_ssh ;;
  8) restore_python_config ;;
  0) exit 0 ;;
  *) log "Invalid option" ;;
esac

log "Restoration complete!"
EOF

# Make the restore script executable
chmod +x "$BACKUP_DIR/restore.sh"

log "Backup completed successfully!"
log "To restore on your new Mac:"
log "1. Copy the $BACKUP_DIR directory to your new Mac"
log "2. Run the restore.sh script inside that directory"

# Create a README file with instructions
cat > "$BACKUP_DIR/README.md" << 'EOF'
# Mac Development Environment Migration

This directory contains a backup of your development environment settings.

## Contents
- iTerm2 settings
- Bash profile files (.bash_profile, .bashrc, .bashrc_gpi)
- Vim configuration
- Git configuration
- Homebrew packages list
- SSH configuration (config only, not keys)
- Python configuration

## How to Restore
1. Copy this entire directory to your new Mac
2. Open Terminal
3. Navigate to this directory: `cd path/to/backup_directory`
4. Run the restore script: `./restore.sh`
5. Follow the prompts to select what you want to restore

## Restore Options
The restore script provides several options:
1. **Everything** - Restore all backed up configurations
2. **iTerm2 settings** - Just restore iTerm2 configuration
3. **Bash profile files** - Restore shell configuration files
4. **Vim configuration** - Restore Vim settings
5. **Git configuration** - Restore Git settings
6. **Homebrew packages** - Install Homebrew packages from the backup
7. **SSH configuration** - Restore SSH config (keys require manual transfer)
8. **Python configuration** - Restore Python environment settings

## Manual Steps
Some items require manual intervention:
- **SSH keys**: For security, you need to manually copy your SSH keys. Use the provided helper script `./ssh/copy_ssh_keys.sh` after reviewing which keys you want to transfer.
- **Application-specific settings**: Some applications may store settings in non-standard locations.

## Troubleshooting
If you encounter any issues during restoration:
- Check the log file (`restore.log`) created in this directory
- Each step can be retried individually if it fails
- For Homebrew issues, you might need to install Homebrew first (the script will offer to do this)
- If a file fails to restore, check if it exists in the backup and if you have proper permissions

## Recovery
The restore script automatically creates backups of existing files before overwriting them. If something goes wrong, you can find the original files with a `.bak.TIMESTAMP` extension.

## Security Notes
- Review all configuration files before restoring them to ensure they don't contain sensitive information
- SSH keys are not automatically copied for security reasons
- Git credentials should be reviewed before restoring
EOF

log "README.md created with detailed instructions" "SUCCESS"

# Run the main backup process
main

exit 0 