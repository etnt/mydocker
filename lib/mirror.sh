#!/usr/bin/env bash
#
# User mirroring functions for mydock
#

# Detect host user information
detect_host_user() {
  local user="${1:-$USER}"
  
  # Get user information
  local uid=$(id -u "${user}")
  local gid=$(id -g "${user}")
  local home=$(eval echo "~${user}")
  local groups=$(id -Gn "${user}" | tr ' ' ',')
  
  # Export for use in other functions
  export DETECTED_USER="${user}"
  export DETECTED_UID="${uid}"
  export DETECTED_GID="${gid}"
  export DETECTED_HOME="${home}"
  export DETECTED_GROUPS="${groups}"
  
  if [[ ${VERBOSE:-0} -eq 1 ]]; then
    msg_info "Detected host user: ${user} (UID:${uid}, GID:${gid})"
    msg_info "Home directory: ${home}"
    msg_info "Groups: ${groups}"
  fi
}

# Setup mirrored user in container
setup_mirror_user() {
  local container_name="$1"
  local username="${2:-$DETECTED_USER}"
  local uid="${3:-$DETECTED_UID}"
  local gid="${4:-$DETECTED_GID}"
  
  if [[ -z "${container_name}" ]]; then
    msg_error "Container name required"
    return 1
  fi
  
  if ! container_exists "${container_name}"; then
    msg_error "Container ${container_name} does not exist"
    return 1
  fi
  
  if ! container_running "${container_name}"; then
    msg_error "Container ${container_name} is not running"
    return 1
  fi
  
  msg_header "Setting up mirrored user in container ${container_name}"
  
  # Create group if it doesn't exist
  msg_info "Creating group ${username} (GID:${gid})..."
  if ! docker_exec_root "${container_name}" "groupadd -f -g ${gid} ${username}" 2>/dev/null; then
    msg_warning "Group may already exist or could not be created"
  fi
  
  # Check if user already exists
  if user_exists_in_container "${container_name}" "${username}"; then
    msg_info "User ${username} already exists in container"
    
    # Update UID/GID if different
    local current_uid=$(docker_exec_root "${container_name}" "id -u ${username}" 2>/dev/null || echo "")
    local current_gid=$(docker_exec_root "${container_name}" "id -g ${username}" 2>/dev/null || echo "")
    
    if [[ "${current_uid}" != "${uid}" ]] || [[ "${current_gid}" != "${gid}" ]]; then
      msg_warning "User exists but UID/GID mismatch. Updating..."
      docker_exec_root "${container_name}" "usermod -u ${uid} -g ${gid} ${username}" 2>/dev/null || true
    fi
  else
    # Create user
    msg_info "Creating user ${username} (UID:${uid}, GID:${gid})..."
    if ! docker_exec_root "${container_name}" "useradd -m -u ${uid} -g ${gid} ${username} -s /bin/bash"; then
      msg_error "Failed to create user ${username}"
      return 1
    fi
  fi
  
  # Add user to sudo group (if it exists)
  msg_info "Configuring sudo access..."
  docker_exec_root "${container_name}" "command -v sudo &>/dev/null && usermod -aG sudo ${username} 2>/dev/null || true"
  
  # Setup passwordless sudo
  docker_exec_root "${container_name}" "mkdir -p /etc/sudoers.d"
  docker_exec_root "${container_name}" "echo '${username}  ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${username}"
  docker_exec_root "${container_name}" "chmod 0440 /etc/sudoers.d/${username}"
  
  msg_success "User ${username} setup complete in container ${container_name}"
  return 0
}

# Build volume mount arguments from MIRROR_DIRS array
build_mirror_mounts() {
  local mounts=""
  
  if [[ -z "${MIRROR_DIRS:-}" ]]; then
    return 0
  fi
  
  # MIRROR_DIRS should be a bash array
  for dir_spec in "${MIRROR_DIRS[@]}"; do
    # Check if it has :ro or :rw suffix
    if [[ "${dir_spec}" =~ ^(.+):(ro|rw)$ ]]; then
      local dir="${BASH_REMATCH[1]}"
      local mode="${BASH_REMATCH[2]}"
      
      # Expand ~ to home directory
      dir="${dir/#\~/$HOME}"
      
      if [[ -e "${dir}" ]]; then
        mounts="${mounts} -v ${dir}:${dir}:${mode}"
      else
        msg_warning "Directory ${dir} does not exist, skipping mount"
      fi
    else
      # No mode specified, use read-write
      local dir="${dir_spec}"
      dir="${dir/#\~/$HOME}"
      
      if [[ -e "${dir}" ]]; then
        mounts="${mounts} -v ${dir}:${dir}"
      else
        msg_warning "Directory ${dir} does not exist, skipping mount"
      fi
    fi
  done
  
  echo "${mounts}"
}

# Setup directories in container after it's running
setup_mirror_directories() {
  local container_name="$1"
  local username="${2:-$DETECTED_USER}"
  local uid="${3:-$DETECTED_UID}"
  local gid="${4:-$DETECTED_GID}"
  
  if [[ -z "${MIRROR_DIRS:-}" ]]; then
    return 0
  fi
  
  msg_info "Setting up directory permissions in container..."
  
  for dir_spec in "${MIRROR_DIRS[@]}"; do
    # Remove :ro or :rw suffix if present
    local dir="${dir_spec%%:*}"
    dir="${dir/#\~/$HOME}"
    
    # Ensure parent directories exist and have correct ownership
    local parent_dir=$(dirname "${dir}")
    
    if [[ "${parent_dir}" == "/home/${username}"* ]]; then
      msg_info "Ensuring ${parent_dir} exists with correct ownership..."
      docker_exec_root "${container_name}" "mkdir -p ${parent_dir}"
      docker_exec_root "${container_name}" "chown ${uid}:${gid} ${parent_dir}"
    fi
  done
  
  # Ensure home directory ownership is correct
  msg_info "Setting ownership of /home/${username}..."
  docker_exec_root "${container_name}" "chown -R ${uid}:${gid} /home/${username}" 2>/dev/null || true
  
  msg_success "Directory permissions configured"
}

# Print mirror configuration
show_mirror_config() {
  if [[ "${MIRROR_USER:-no}" == "yes" ]] || [[ -n "${MIRROR_USER_NAME:-}" ]]; then
    msg_header "User Mirroring Configuration:"
    echo "  User:   ${MIRROR_USER_NAME:-$USER}"
    echo "  UID:    ${MIRROR_USER_UID:-$(id -u)}"
    echo "  GID:    ${MIRROR_USER_GID:-$(id -g)}"
    
    if [[ -n "${MIRROR_DIRS:-}" ]]; then
      echo "  Directories:"
      for dir in "${MIRROR_DIRS[@]}"; do
        echo "    - ${dir}"
      done
    fi
  fi
}
