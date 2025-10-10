#!/usr/bin/env bash
#
# Configuration wizard for mydock
#

# Wizard to create a new configuration file
config_wizard() {
  msg_header "mydock Configuration Wizard"
  echo ""
  echo "This wizard will help you create a new container configuration file."
  echo ""
  
  # Variables to collect
  local repo=""
  local tag="latest"
  local name=""
  local hostname=""
  local shared_dir=""
  local ports=""
  local extra_ports=()
  local mirror_user="no"
  local mirror_dirs=()
  local network_name=""
  local network_driver="bridge"
  local network_create="no"
  local config_filename=""
  
  # Step 1: Choose image
  msg_header "Step 1: Docker Image"
  echo ""
  echo "Available images on your system:"
  sudo docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" 2>/dev/null || true
  echo ""
  
  read -e -p "Enter image repository (or 'custom' for URL): " repo
  
  if [[ -z "${repo}" ]]; then
    msg_error "Repository cannot be empty"
    return 1
  fi
  
  if [[ "${repo}" == "custom" ]]; then
    read -e -p "Enter full image URL (e.g., myregistry.com:5000/myimage): " repo
  fi
  
  read -e -p "Enter image tag [latest]: " tag
  tag="${tag:-latest}"
  
  # Step 2: Container details
  echo ""
  msg_header "Step 2: Container Details"
  echo ""
  
  read -e -p "Enter container name: " name
  if [[ -z "${name}" ]]; then
    msg_error "Container name cannot be empty"
    return 1
  fi
  
  read -e -p "Enter hostname [${name}]: " hostname
  hostname="${hostname:-$name}"
  
  # Step 3: Directory mapping
  echo ""
  msg_header "Step 3: Directory Mapping"
  echo ""
  
  read -e -p "Enter shared directory path (required): " shared_dir
  if [[ -z "${shared_dir}" ]]; then
    msg_error "Shared directory cannot be empty"
    return 1
  fi
  
  # Expand ~ to home directory
  shared_dir="${shared_dir/#\~/$HOME}"
  
  # Check if directory exists
  if [[ ! -d "${shared_dir}" ]]; then
    read -e -p "Directory does not exist. Create it? [y/N]: " create_dir
    if [[ "${create_dir}" =~ ^[Yy] ]]; then
      mkdir -p "${shared_dir}"
      msg_success "Created directory: ${shared_dir}"
    fi
  fi
  
  # Step 4: User mirroring
  echo ""
  msg_header "Step 4: User Mirroring"
  echo ""
  echo "User mirroring creates a user in the container matching your host user."
  echo "This ensures file ownership is correct when editing files from the container."
  echo ""
  
  read -e -p "Enable user mirroring? [Y/n]: " enable_mirror
  if [[ ! "${enable_mirror}" =~ ^[Nn] ]]; then
    mirror_user="yes"

    # Ask about common directories
    echo ""
    echo "Common directories you might want to mount:"
    echo ""
    
    read -e -p "Mount ~/.gitconfig (read-only) for Git configuration? [Y/n]: " add_git
    if [[ ! "${add_git}" =~ ^[Nn] ]]; then
      # Properly expand HOME variable
      local gitconfig_path="${HOME}/.gitconfig:ro"
      mirror_dirs+=("${gitconfig_path}")
      msg_success "Added: ${gitconfig_path}"
    fi
    
    read -e -p "Mount ~/.ssh (read-only) for SSH keys? [Y/n]: " add_ssh
    if [[ ! "${add_ssh}" =~ ^[Nn] ]]; then
      # Properly expand HOME variable
      local ssh_path="${HOME}/.ssh:ro"
      mirror_dirs+=("${ssh_path}")
      msg_success "Added: ${ssh_path}"
    fi

    read -e -p "Mount ~/.bashrc (read-only) for shell configuration? [Y/n]: " add_bashrc
    if [[ ! "${add_bashrc}" =~ ^[Nn] ]]; then
      local bashrc_path="${HOME}/.bashrc:ro"
      mirror_dirs+=("${bashrc_path}")
      msg_success "Added: ${bashrc_path}"
    fi
    
    echo ""
    echo "Additional directories to mount (with matching paths):"
    echo "Press Enter with empty input when done."
    echo "Use ':ro' suffix for read-only mounts (e.g., /home/user/.ssh:ro)"
    echo ""
    
    while true; do
      read -e -p "Directory path (or Enter to finish): " dir_path
      if [[ -z "${dir_path}" ]]; then
        break
      fi
      
      # Expand ~ to home directory
      dir_path="${dir_path/#\~/$HOME}"
      
      mirror_dirs+=("${dir_path}")
      msg_success "Added: ${dir_path}"
    done
    
  fi
  
  # Step 5: Port mapping
  echo ""
  msg_header "Step 5: Port Mapping"
  echo ""
  echo "Map ports from host to container (format: HOST:CONTAINER)."
  echo "Press Enter with empty input when done."
  echo ""
  
  while true; do
    read -e -p "Port mapping (e.g., 8080:80) or Enter to finish: " port_map
    if [[ -z "${port_map}" ]]; then
      break
    fi
    
    if [[ "${port_map}" =~ ^[0-9]+:[0-9]+$ ]]; then
      if [[ -z "${ports}" ]]; then
        ports="${port_map}"
      else
        extra_ports+=("-p ${port_map}")
      fi
      msg_success "Added port mapping: ${port_map}"
    else
      msg_warning "Invalid format. Use HOST:CONTAINER (e.g., 8080:80)"
    fi
  done
  
  # Step 6: Networking
  echo ""
  msg_header "Step 6: Docker Networking"
  echo ""
  
  read -e -p "Configure Docker network? [y/N]: " setup_network
  if [[ "${setup_network}" =~ ^[Yy] ]]; then
    echo ""
    echo "Available networks:"
    sudo docker network ls 2>/dev/null || true
    echo ""
    
    read -e -p "Enter network name (or create new): " network_name
    
    if [[ -n "${network_name}" ]]; then
      if ! network_exists "${network_name}"; then
        read -e -p "Network doesn't exist. Auto-create it? [Y/n]: " auto_create
        if [[ ! "${auto_create}" =~ ^[Nn] ]]; then
          network_create="yes"
          
          read -e -p "Network driver [bridge]: " network_driver
          network_driver="${network_driver:-bridge}"
        fi
      fi
    fi
  fi
  
  # Step 7: Generate config file
  echo ""
  msg_header "Step 7: Save Configuration"
  echo ""
  
  # Ensure conf directory exists
  mkdir -p "${CONF_DIR}"
  
  # Suggest filename
  local suggested_name="${name}.conf"
  read -e -p "Configuration filename [${suggested_name}]: " config_filename
  config_filename="${config_filename:-$suggested_name}"
  
  # Add .conf extension if not present
  if [[ ! "${config_filename}" =~ \.conf$ ]]; then
    config_filename="${config_filename}.conf"
  fi
  
  # Full path to config file
  local config_filepath="${CONF_DIR}/${config_filename}"
  
  # Check if file exists
  if [[ -f "${config_filepath}" ]]; then
    read -e -p "File exists. Overwrite? [y/N]: " overwrite
    if [[ ! "${overwrite}" =~ ^[Yy] ]]; then
      msg_warning "Cancelled. Configuration not saved."
      return 1
    fi
  fi
  
  # Generate the configuration file
  echo ""
  msg_info "Generating configuration file: ${config_filepath}"
  
  cat > "${config_filepath}" << EOF
# mydock configuration file
# Generated by wizard on $(date '+%Y-%m-%d %H:%M:%S')

# Container image
REPOSITORY=${repo}
TAG=${tag}

# Container details
NAME=${name}
HOSTNAME=${hostname}

# Directory mapping
SHARED_DIR=${shared_dir}

EOF
  
  # Add port mappings
  if [[ -n "${ports}" ]]; then
    echo "# Port mappings" >> "${config_filepath}"
    echo "PORTS=${ports}" >> "${config_filepath}"
    
    if [[ ${#extra_ports[@]} -gt 0 ]]; then
      # Join extra ports with space
      local extra_flags="${extra_ports[*]}"
      echo "EXTRA_RUN_FLAGS=\"${extra_flags}\"" >> "${config_filepath}"
    fi
    echo "" >> "${config_filepath}"
  fi
  
  # Add user mirroring section
  if [[ "${mirror_user}" == "yes" ]]; then
    cat >> "${config_filepath}" << EOF
# ========================================
# User Mirroring Configuration
# ========================================
# Enable automatic user mirroring
MIRROR_USER=yes

# User settings (auto-detected if not specified)
MIRROR_USER_NAME=${USER}
MIRROR_USER_UID=$(id -u)
MIRROR_USER_GID=$(id -g)

EOF
    
    if [[ ${#mirror_dirs[@]} -gt 0 ]]; then
      echo "# Directories to mount with matching paths" >> "${config_filepath}"
      echo "MIRROR_DIRS=(" >> "${config_filepath}"
      for dir in "${mirror_dirs[@]}"; do
        echo "  \"${dir}\"" >> "${config_filepath}"
      done
      echo ")" >> "${config_filepath}"
      echo "" >> "${config_filepath}"
    fi
  fi
  
  # Add network configuration
  if [[ -n "${network_name}" ]]; then
    cat >> "${config_filepath}" << EOF
# ========================================
# Network Configuration
# ========================================
NETWORK_NAME=${network_name}
NETWORK_DRIVER=${network_driver}
NETWORK_CREATE_IF_MISSING=${network_create}

EOF
  fi
  
  # Add comments section
  cat >> "${config_filepath}" << 'EOF'
# ========================================
# Additional Notes
# ========================================
# To use this configuration:
#   ./mydock run --config <this-file>
#
# To preview the docker command:
#   ./mydock run --config <this-file> --dry-run
#
# To enter the container:
#   ./mydock shell --name <container-name>
#   ./mydock user --name <container-name> --user <username>
EOF
  
  msg_success "Configuration saved to: ${config_filepath}"
  echo ""
  
  # Show the configuration
  msg_header "Generated Configuration"
  cat "${config_filepath}"
  echo ""
  
  # Offer to run it
  read -e -p "Would you like to run this configuration now? [y/N]: " run_now
  if [[ "${run_now}" =~ ^[Yy] ]]; then
    echo ""
    read -e -p "Dry-run first to see the command? [Y/n]: " dry_first
    if [[ ! "${dry_first}" =~ ^[Nn] ]]; then
      msg_info "Running dry-run..."
      config_file="${config_filename}"
      config
      dry_run=1
      run
      echo ""
    fi
    
    read -e -p "Create and start the container? [y/N]: " create_now
    if [[ "${create_now}" =~ ^[Yy] ]]; then
      config_file="${config_filename}"
      config
      dry_run=0
      run
    fi
  else
    echo ""
    msg_info "To use this configuration later:"
    echo "  ./mydock run --config ${config_filename}"
  fi
  
  return 0
}

# Quick wizard - minimal questions for fast setup
quick_wizard() {
  msg_header "mydock Quick Setup"
  echo ""
  
  local repo=""
  local name=""
  local dir=""
  local add_git="y"
  local add_ssh="y"
  
  # Ensure conf directory exists
  mkdir -p "${CONF_DIR}"
  
  # Show available images
  echo "Recent images:"
  sudo docker images --format "table {{.Repository}}\t{{.Tag}}" 2>/dev/null | head -6 || true
  echo ""
  
  read -e -p "Image repository: " repo
  [[ -z "${repo}" ]] && { msg_error "Repository required"; return 1; }
  
  read -e -p "Container name: " name
  [[ -z "${name}" ]] && { msg_error "Name required"; return 1; }
  
  read -e -p "Directory to map: " dir
  dir="${dir/#\~/$HOME}"
  [[ -z "${dir}" ]] && { msg_error "Directory required"; return 1; }
  
  # Quick questions about common directories
  read -e -p "Mount ~/.gitconfig (read-only)? [Y/n]: " add_git
  read -e -p "Mount ~/.ssh (read-only)? [Y/n]: " add_ssh
  
  local config_name="${name}.conf"
  local config_path="${CONF_DIR}/${config_name}"
  
  # Build the config file
  cat > "${config_path}" << EOF
# Quick setup configuration
REPOSITORY=${repo}
TAG=latest
NAME=${name}
HOSTNAME=${name}
SHARED_DIR=${dir}

# User mirroring enabled
MIRROR_USER=yes
MIRROR_DIRS=(
  "${dir}"
EOF
  
  # Add gitconfig if requested
  if [[ ! "${add_git}" =~ ^[Nn] ]]; then
    echo "  \"${HOME}/.gitconfig:ro\"" >> "${config_path}"
  fi
  
  # Add ssh if requested
  if [[ ! "${add_ssh}" =~ ^[Nn] ]]; then
    echo "  \"${HOME}/.ssh:ro\"" >> "${config_path}"
  fi
  
  # Close the array
  echo ")" >> "${config_path}"
  
  msg_success "Created: ${config_path}"
  echo ""
  cat "${config_path}"
  echo ""
  
  read -e -p "Run now? [y/N]: " run_it
  if [[ "${run_it}" =~ ^[Yy] ]]; then
    config_file="${config_name}"
    config
    dry_run=0
    run
  fi
}
