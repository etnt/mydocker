#!/usr/bin/env bash
#
# Network management functions for mydock
#

# Create a Docker network
network_create() {
  local network_name="${NETWORK_NAME}"
  local driver="${NETWORK_DRIVER:-bridge}"
  local subnet="${NETWORK_SUBNET}"
  local gateway="${NETWORK_GATEWAY}"
  local internal="${NETWORK_INTERNAL:-no}"
  
  if [[ -z "${network_name}" ]]; then
    msg_error "Network name required"
    return 1
  fi
  
  if network_exists "${network_name}"; then
    msg_warning "Network ${network_name} already exists"
    return 0
  fi
  
  msg_info "Creating network ${network_name} with driver ${driver}..."
  
  local cmd="sudo docker network create --driver ${driver}"
  
  if [[ -n "${subnet}" ]]; then
    cmd="${cmd} --subnet=${subnet}"
  fi
  
  if [[ -n "${gateway}" ]]; then
    cmd="${cmd} --gateway=${gateway}"
  fi
  
  if [[ "${internal}" == "yes" ]]; then
    cmd="${cmd} --internal"
  fi
  
  cmd="${cmd} ${network_name}"
  
  if [[ ${dry_run} -eq 1 ]]; then
    echo "${cmd}"
    return 0
  fi
  
  if eval "${cmd}"; then
    msg_success "Network ${network_name} created"
    return 0
  else
    msg_error "Failed to create network ${network_name}"
    return 1
  fi
}

# List Docker networks
network_list() {
  echo "sudo docker network ls"
  if [[ ${dry_run} -eq 0 ]]; then
    sudo docker network ls
  fi
}

# Inspect a Docker network
network_inspect() {
  local network_name="$1"
  
  if [[ -z "${network_name}" ]]; then
    msg_error "Network name required"
    return 1
  fi
  
  echo "sudo docker network inspect ${network_name}"
  if [[ ${dry_run} -eq 0 ]]; then
    sudo docker network inspect "${network_name}"
  fi
}

# Remove a Docker network
network_remove() {
  local network_name="$1"
  
  if [[ -z "${network_name}" ]]; then
    msg_error "Network name required"
    return 1
  fi
  
  if ! network_exists "${network_name}"; then
    msg_error "Network ${network_name} does not exist"
    return 1
  fi
  
  echo "sudo docker network rm ${network_name}"
  if [[ ${dry_run} -eq 0 ]]; then
    if sudo docker network rm "${network_name}"; then
      msg_success "Network ${network_name} removed"
    else
      msg_error "Failed to remove network ${network_name}"
      return 1
    fi
  fi
}

# Connect container to network
network_connect() {
  local network_name="$1"
  local container_name="$2"
  
  if [[ -z "${network_name}" ]] || [[ -z "${container_name}" ]]; then
    msg_error "Usage: network_connect <network> <container>"
    return 1
  fi
  
  if ! network_exists "${network_name}"; then
    msg_error "Network ${network_name} does not exist"
    return 1
  fi
  
  if ! container_exists "${container_name}"; then
    msg_error "Container ${container_name} does not exist"
    return 1
  fi
  
  echo "sudo docker network connect ${network_name} ${container_name}"
  if [[ ${dry_run} -eq 0 ]]; then
    if sudo docker network connect "${network_name}" "${container_name}"; then
      msg_success "Container ${container_name} connected to network ${network_name}"
    else
      msg_error "Failed to connect container to network"
      return 1
    fi
  fi
}

# Disconnect container from network
network_disconnect() {
  local network_name="$1"
  local container_name="$2"
  
  if [[ -z "${network_name}" ]] || [[ -z "${container_name}" ]]; then
    msg_error "Usage: network_disconnect <network> <container>"
    return 1
  fi
  
  echo "sudo docker network disconnect ${network_name} ${container_name}"
  if [[ ${dry_run} -eq 0 ]]; then
    if sudo docker network disconnect "${network_name}" "${container_name}"; then
      msg_success "Container ${container_name} disconnected from network ${network_name}"
    else
      msg_error "Failed to disconnect container from network"
      return 1
    fi
  fi
}

# Auto-create network if specified in config
auto_create_network() {
  if [[ "${NETWORK_CREATE_IF_MISSING:-no}" == "yes" ]] && [[ -n "${NETWORK_NAME:-}" ]]; then
    if ! network_exists "${NETWORK_NAME}"; then
      msg_info "Auto-creating network ${NETWORK_NAME}..."
      network_create
    fi
  fi
}

# Build network flags for docker run command
build_network_flags() {
  local flags=""
  
  if [[ -n "${NETWORK_NAME:-}" ]]; then
    flags="--network ${NETWORK_NAME}"
  fi
  
  echo "${flags}"
}

# Show network configuration
show_network_config() {
  if [[ -n "${NETWORK_NAME:-}" ]]; then
    msg_header "Network Configuration:"
    echo "  Network:  ${NETWORK_NAME}"
    echo "  Driver:   ${NETWORK_DRIVER:-bridge}"
    if [[ -n "${NETWORK_SUBNET:-}" ]]; then
      echo "  Subnet:   ${NETWORK_SUBNET}"
    fi
    if [[ -n "${NETWORK_GATEWAY:-}" ]]; then
      echo "  Gateway:  ${NETWORK_GATEWAY}"
    fi
    if [[ "${NETWORK_CREATE_IF_MISSING:-no}" == "yes" ]]; then
      echo "  Auto-create: yes"
    fi
  fi
}
