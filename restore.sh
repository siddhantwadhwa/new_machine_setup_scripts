# Update the restore_bash_profiles function

restore_bash_profiles() {
  log "Restoring shell configuration files" "INFO"
  
  # Restore bash_profile which should be in the backup
  restore_item "$SCRIPT_DIR/.bash_profile" "$HOME/.bash_profile" "Bash profile"
  
  # Restore any other shell config files that were backed up
  for shell_file in "$SCRIPT_DIR"/.{bashrc,profile,zshrc,zprofile,zsh_history,bash_history}; do
    if [ -f "$shell_file" ]; then
      restore_item "$shell_file" "$HOME/$(basename "$shell_file")" "Shell configuration file"
    fi
  done
  
  # Restore conda configuration if it exists
  if [ -d "$SCRIPT_DIR/.conda" ]; then
    restore_item "$SCRIPT_DIR/.conda" "$HOME/.conda" "Conda configuration"
  fi
  
  # Check if we need to install Miniconda on the new system
  if [ -f "$SCRIPT_DIR/miniconda_path.txt" ]; then
    old_miniconda_path=$(cat "$SCRIPT_DIR/miniconda_path.txt")
    log "Note: Your old system had Miniconda installed at: $old_miniconda_path" "INFO"
    
    # Check if Miniconda is installed at the same path on the new system
    if [ ! -d "$old_miniconda_path" ]; then
      log "Miniconda not found at the same path on this system" "WARNING"
      log "You may need to install Miniconda and update your .bash_profile" "WARNING"
      
      read -p "Would you like to download and install Miniconda now? (y/n): " install_miniconda
      if [[ "$install_miniconda" =~ ^[Yy]$ ]]; then
        log "Downloading Miniconda installer..." "INFO"
        
        # Determine OS and architecture
        if [[ "$(uname)" == "Darwin" ]]; then
          if [[ "$(uname -m)" == "x86_64" ]]; then
            miniconda_installer="Miniconda3-latest-MacOSX-x86_64.sh"
          else
            miniconda_installer="Miniconda3-latest-MacOSX-arm64.sh"
          fi
        else
          log "Unsupported OS for automatic Miniconda installation" "ERROR"
          return 1
        fi
        
        curl -O "https://repo.anaconda.com/miniconda/$miniconda_installer" || {
          log "Failed to download Miniconda installer" "ERROR"
          return 1
        }
        
        # Install Miniconda
        bash "$miniconda_installer" -b -p "$old_miniconda_path" || {
          log "Failed to install Miniconda" "ERROR"
          return 1
        }
        
        # Initialize conda in the current shell
        eval "$("$old_miniconda_path/bin/conda" 'shell.bash' 'hook')"
        
        # Clean up
        rm "$miniconda_installer"
        
        log "Miniconda installed successfully at $old_miniconda_path" "SUCCESS"
      fi
    else
      log "Miniconda found at expected path: $old_miniconda_path" "SUCCESS"
    fi
  fi
  
  log "Shell configuration files restored. You may need to restart your terminal." "INFO"
  return 0
} 