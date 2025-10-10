#!/usr/bin/env bash
#
# Interactive shell mode for mydock
#

# Interactive mode state
INTERACTIVE_CONFIG=""
INTERACTIVE_NAME=""

# Helper function to ensure we have a container name
# Can take an optional argument to override
# Falls back to INTERACTIVE_NAME, then NAME from config
ensure_container_name() {
  local override_name="${1:-}"
  
  if [[ -n "${override_name}" ]]; then
    # Use the provided override
    INTERACTIVE_NAME="${override_name}"
    NAME="${override_name}"
  elif [[ -z "${INTERACTIVE_NAME}" ]]; then
    if [[ -n "${NAME}" ]]; then
      INTERACTIVE_NAME="${NAME}"
    else
      msg_error "No active container. Use 'use <config>' first or provide container name"
      return 1
    fi
  fi
  return 0
}

# Start interactive shell
interactive_shell() {
  msg_header "mydock Interactive Mode"
  echo "Type 'help' for available commands, 'exit' or 'quit' to leave"
  echo ""
  
  # Load history if available
  local history_file="${HOME}/.mydock_history"
  if [[ -f "${history_file}" ]]; then
    history -r "${history_file}"
  fi
  
  while true; do
    # Build prompt
    local prompt="mydock"
    if [[ -n "${INTERACTIVE_CONFIG}" ]]; then
      prompt="${prompt} [${INTERACTIVE_CONFIG}]"
    elif [[ -n "${INTERACTIVE_NAME}" ]] || [[ -n "${NAME}" ]]; then
      # Only show container name if no config is loaded
      prompt="${prompt} (${INTERACTIVE_NAME:-${NAME}})"
    fi
    prompt="${prompt}> "
    
    # Read command
    read -e -p "${prompt}" cmd args
    
    # Save to history
    if [[ -n "${cmd}" ]]; then
      history -s "${cmd} ${args}"
    fi
    
    # Handle empty input
    if [[ -z "${cmd}" ]]; then
      continue
    fi
    
    # Process command
    case "${cmd}" in
      exit|quit)
        msg_info "Exiting interactive mode"
        # Save history
        history -w "${history_file}"
        break
        ;;
      
      help)
        interactive_help
        ;;
      
      use)
        if [[ -z "${args}" ]]; then
          msg_error "Usage: use <config-file>"
        else
          # Check if file exists in current dir, otherwise try conf/ dir
          local conf_path=""
          if [[ -f "${args}" ]]; then
            conf_path="${args}"
          elif [[ -f "${CONF_DIR}/${args}" ]]; then
            conf_path="${args}"  # Will be resolved by config() function
          else
            msg_error "Config file not found: ${args}"
            continue
          fi
          
          INTERACTIVE_CONFIG="${args}"
          config_file="${args}"
          config
          msg_success "Using config: ${args}"
        fi
        ;;
      
      set)
        interactive_set ${args}
        ;;
      
      show|show_config)
        show_config
        ;;
      
      run)
        # Check if --dry-run is in args
        if [[ "${args}" == *"--dry-run"* ]]; then
          dry_run=1
        else
          dry_run=0
        fi
        run
        ;;
      
      start)
        if ensure_container_name "${args}"; then
          start
        fi
        ;;
      
      stop)
        if ensure_container_name "${args}"; then
          stop
        fi
        ;;
      
      rm|remove)
        if ensure_container_name "${args}"; then
          remove
        fi
        ;;
      
      shell)
        if ensure_container_name "${args}"; then
          _shell
        fi
        ;;
      
      user)
        # Parse args: can be <container> or <username> or <container> <username>
        local container_arg=""
        local user_arg=""
        
        if [[ -n "${args}" ]]; then
          # Check if we have two args (container + username)
          if [[ "${args}" =~ ^([^ ]+)\ +(.+)$ ]]; then
            container_arg="${BASH_REMATCH[1]}"
            user_arg="${BASH_REMATCH[2]}"
          else
            # Single arg - could be container or username
            # If it matches a known container or we don't have NAME set, treat as container
            if [[ -z "${NAME}" ]] || sudo docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${args}$"; then
              container_arg="${args}"
            else
              user_arg="${args}"
            fi
          fi
        fi
        
        if ensure_container_name "${container_arg}"; then
          if [[ -z "${user_arg}" ]]; then
            # Use detected or configured user
            if [[ -n "${MIRROR_USER_NAME}" ]]; then
              USER="${MIRROR_USER_NAME}"
            else
              msg_error "Usage: user [container] [username]"
              continue
            fi
          else
            USER="${user_arg}"
          fi
          user
        fi
        ;;
      
      sync)
        if ensure_container_name "${args}"; then
          sync
        fi
        ;;
      
      setup_mirror|mirror)
        if ensure_container_name "${args}"; then
          setup_mirror
        fi
        ;;
      
      ps|list)
        _ps
        ;;
      
      images|imgs)
        images
        ;;
      
      logs)
        if ensure_container_name "${args}"; then
          logs
        fi
        ;;
      
      network)
        interactive_network ${args}
        ;;
      
      configs|list-configs)
        list_configs
        ;;
      
      wizard)
        config_wizard
        ;;
      
      quick)
        quick_wizard
        ;;
      
      clear)
        clear
        ;;
      
      *)
        msg_error "Unknown command: ${cmd}"
        echo "Type 'help' for available commands"
        ;;
    esac
  done
}

# Interactive help
interactive_help() {
  cat << 'EOF'
Interactive Mode Commands:

Configuration:
  use <config>           Load configuration file
  set <param> <value>    Set configuration parameter
  show                   Show current configuration
  configs                List available config files
  wizard                 Run configuration wizard (create new config)
  quick                  Quick setup wizard (minimal questions)

Container Operations:
  run [--dry-run]        Create and start container
  start [container]      Start container (uses config if no name given)
  stop [container]       Stop container (uses config if no name given)
  rm [container]         Remove container (uses config if no name given)
  shell [container]      Enter container shell (uses config if no name given)
  user [container] [usr] Enter as user (uses config/mirror user if not specified)
  sync [container]       Commit container changes to image
  setup_mirror [cont]    Set up mirrored user and directories
  logs [container]       Show logs (uses config if no name given)

Information:
  ps, list               List all containers
  images, imgs           List all images
  network <cmd>          Network commands (list, inspect, etc.)

Other:
  help                   Show this help
  clear                  Clear screen
  exit, quit             Exit interactive mode

Examples:
  mydock> wizard                  # Create new config interactively
  mydock> use debian.conf         # Load config
  mydock> start                   # Start container from config
  mydock> shell                   # Enter shell in config's container
  mydock> stop sp80               # Stop specific container by name
  mydock> user sp80 alice         # Enter sp80 container as alice
EOF
}

# Handle 'set' command in interactive mode
interactive_set() {
  local param="$1"
  local value="$2"
  
  if [[ -z "${param}" ]] || [[ -z "${value}" ]]; then
    msg_error "Usage: set <parameter> <value>"
    return 1
  fi
  
  case "${param}" in
    name)
      NAME="${value}"
      INTERACTIVE_NAME="${value}"
      msg_success "NAME set to: ${value}"
      ;;
    tag)
      TAG="${value}"
      msg_success "TAG set to: ${value}"
      ;;
    repository)
      REPOSITORY="${value}"
      msg_success "REPOSITORY set to: ${value}"
      ;;
    hostname)
      HOSTNAME="${value}"
      msg_success "HOSTNAME set to: ${value}"
      ;;
    *)
      msg_error "Unknown parameter: ${param}"
      echo "Available parameters: name, tag, repository, hostname"
      return 1
      ;;
  esac
}

# Handle network commands in interactive mode
interactive_network() {
  local subcmd="$1"
  shift
  local args="$@"
  
  case "${subcmd}" in
    list|ls)
      network_list
      ;;
    inspect)
      network_inspect ${args}
      ;;
    create)
      network_create
      ;;
    rm|remove)
      network_remove ${args}
      ;;
    connect)
      network_connect ${args}
      ;;
    disconnect)
      network_disconnect ${args}
      ;;
    help|*)
      echo "Network commands:"
      echo "  network list              - List all networks"
      echo "  network inspect <network> - Inspect network details"
      echo "  network create            - Create network from config"
      echo "  network rm <network>      - Remove a network"
      echo "  network connect <network> <container>"
      echo "  network disconnect <network> <container>"
      ;;
  esac
}

# List available config files
list_configs() {
  msg_header "Available configuration files:"
  local configs=$(ls -1 "${CONF_DIR}"/*.conf 2>/dev/null | xargs -n 1 basename 2>/dev/null)
  if [[ -n "${configs}" ]]; then
    echo "${configs}" | while read conf; do
      echo "  - ${conf}"
    done
  else
    echo "  No .conf files found in ${CONF_DIR}"
  fi
}
