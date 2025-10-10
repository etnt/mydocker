#!/usr/bin/env bash
#
# Utility functions for mydock
#

# Color codes for output
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  MAGENTA='\033[0;35m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  NC='\033[0m' # No Color
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  MAGENTA=''
  CYAN=''
  BOLD=''
  NC=''
fi

# Print colored message
msg_info() {
  echo -e "${BLUE}ℹ${NC} $*" >&2
}

msg_success() {
  echo -e "${GREEN}✓${NC} $*" >&2
}

msg_warning() {
  echo -e "${YELLOW}⚠${NC} $*" >&2
}

msg_error() {
  echo -e "${RED}✗${NC} $*" >&2
}

msg_header() {
  echo -e "${BOLD}${CYAN}$*${NC}" >&2
}

# Check if docker is available
check_docker() {
  if ! command -v docker &> /dev/null; then
    msg_error "Docker is not installed or not in PATH"
    return 1
  fi
  
  if ! sudo docker info &> /dev/null; then
    msg_error "Cannot connect to Docker daemon. Is Docker running?"
    return 1
  fi
  
  return 0
}

# Check if container exists
container_exists() {
  local container_name="$1"
  sudo docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"
}

# Check if container is running
container_running() {
  local container_name="$1"
  sudo docker ps --format '{{.Names}}' | grep -q "^${container_name}$"
}

# Check if network exists
network_exists() {
  local network_name="$1"
  sudo docker network ls --format '{{.Name}}' | grep -q "^${network_name}$"
}

# Execute command in container as root
docker_exec_root() {
  local container_name="$1"
  shift
  sudo docker exec -u root "${container_name}" bash -c "$@"
}

# Check if user exists in container
user_exists_in_container() {
  local container_name="$1"
  local username="$2"
  docker_exec_root "${container_name}" "id ${username} &>/dev/null"
}
