# mydock Enhancement Plan

## Current State Analysis

The `mydock` script is a useful wrapper around Docker commands that:
- Provides a simplified interface for common Docker operations
- Supports configuration files for different container setups
- Offers dry-run mode for previewing commands
- Handles basic container lifecycle (build, run, start, stop, shell access)
- Manages user setup within containers

## Proposed Enhancements

### 1. Interactive Shell Mode

#### 1.1 Basic Shell Features
**Goal:** Create a REPL (Read-Eval-Print Loop) environment for easier interaction

**Implementation:**
- Add a new `interactive` or `shell-mode` command
- Use `read -e -p "mydock> "` for command input with readline support
- Enable command history with `history` command
- Add tab completion for commands and container names
- Display current active container/config in prompt

**Commands to Support:**
```
mydock> use <config-file>     # Switch active configuration
mydock> set name <name>        # Override config parameters
mydock> show                   # Display current config
mydock> run                    # Execute using current config
mydock> attach <container>     # Switch active container
mydock> exit/quit             # Leave interactive mode
```

#### 1.2 Enhanced Shell Features
- Command aliases (e.g., `ls` → `ps`, `i` → `images`)
- Multi-line command support for complex operations
- Command history persistence (~/.mydock_history)
- Context-aware tab completion
- Colored output for better readability
- Built-in help for each command (help <command>)

### 2. Docker Networking Support

#### 2.1 Network Management Commands
**Goal:** Simplify Docker network operations

**New Commands:**
```bash
./mydock network create <name> [--driver bridge|overlay|host]
./mydock network list
./mydock network inspect <name>
./mydock network remove <name>
./mydock network connect <network> <container>
./mydock network disconnect <network> <container>
```

#### 2.2 Network Configuration in Config Files
**Enhanced config file format:**
```bash
# Existing parameters
REPOSITORY=myrepo/myimage
TAG=v1
NAME=mycontainer

# New network parameters
NETWORK_NAME=mybridge           # Network to use/create
NETWORK_DRIVER=bridge           # Network driver type
NETWORK_SUBNET=172.18.0.0/16    # Optional: subnet configuration
NETWORK_GATEWAY=172.18.0.1      # Optional: gateway
NETWORK_CREATE_IF_MISSING=yes   # Auto-create network
```

#### 2.3 Network Templates
Create predefined network configurations:
```bash
# network-templates/isolated.conf
NETWORK_NAME=isolated_net
NETWORK_DRIVER=bridge
NETWORK_INTERNAL=yes

# network-templates/multi-host.conf
NETWORK_NAME=overlay_net
NETWORK_DRIVER=overlay
NETWORK_ATTACHABLE=yes
```

### 3. Additional Useful Features

#### 3.1 Host User Mirroring
**Goal:** Seamlessly work with host files from within containers

**Problem:** When mounting host directories, file ownership mismatches cause permission issues and files created in containers appear with wrong ownership on the host.

**Solution:** Automatically create a user in the container matching the host user's UID/GID and mount directories with matching paths.

**New Commands:**
```bash
./mydock run --mirror-user          # Auto-detect and mirror current host user
./mydock run --mirror-user <user>   # Mirror specific host user
./mydock setup-mirror-user          # Setup user in existing container
```

**Config File Parameters:**
```bash
# Enable automatic user mirroring
MIRROR_USER=yes                     # Mirror current host user
MIRROR_USER_NAME=tobbe              # Or specify user to mirror
MIRROR_USER_UID=1000                # Auto-detected if not specified
MIRROR_USER_GID=1000                # Auto-detected if not specified
MIRROR_USER_GROUPS="docker,sudo"    # Additional groups for container user
MIRROR_USER_HOME=/home/tobbe        # Home directory (auto-detected)

# Directory mappings - auto-create matching paths in container
MIRROR_DIRS=(
  "/home/tobbe/work/git/trunk"
  "/home/tobbe/projects"
  "/home/tobbe/.ssh:ro"             # Read-only mapping
)

# Or use simple pattern matching
MIRROR_DIRS_PATTERN="/home/tobbe/work/*"  # Auto-discover and map
```

**Implementation Details:**
1. Detect host user information (UID, GID, username, home, groups)
2. Create matching user in container during `run` or via separate command
3. Auto-generate volume mount flags for specified directories
4. Optionally create missing directories in container
5. Set proper ownership after directory creation
6. Configure sudo access for the mirrored user

**Enhanced `run` command behavior:**
```bash
# Traditional way (current)
./mydock run --config debian.conf -v /home/tobbe/work:/home/tobbe/work

# With user mirroring (proposed)
./mydock run --config debian-dev.conf --mirror-user
# Automatically:
# - Creates user 'tobbe' with same UID/GID in container
# - Mounts configured directories with matching paths
# - Sets up sudo access
# - Starts container as the mirrored user (optional)
```

### 3.2 Container Profiles/Templates
- Store common configurations as profiles
- Quick switch between profiles
- Profile inheritance (base configs extended by specific ones)

Example structure:
```
profiles/
  base.conf           # Common settings
  dev.conf            # Development environment (with user mirroring)
  prod.conf           # Production-like setup
  testing.conf        # Testing environment
```

#### 3.3 Multi-Container Management
- Support for docker-compose-like operations
- Group operations (start/stop multiple containers)
- Container dependencies
- Health checks

```bash
./mydock group create <group-name> <container1> <container2>
./mydock group start <group-name>
./mydock group stop <group-name>
```

#### 3.4 Volume Management
```bash
./mydock volume create <name>
./mydock volume list
./mydock volume inspect <name>
./mydock volume remove <name>
./mydock volume attach <volume> <container> <mount-point>
```

#### 3.5 Enhanced Monitoring
```bash
./mydock stats [<container>]      # Resource usage
./mydock top <container>          # Processes in container
./mydock inspect <container>      # Detailed info
./mydock events [--since <time>]  # Docker events
```

#### 3.6 Backup/Restore Operations
```bash
./mydock export <container> <tarfile>
./mydock import <tarfile> <repository:tag>
./mydock save <image> <tarfile>
./mydock load <tarfile>
```

#### 3.7 Configuration Management
```bash
./mydock config list              # Show all configs
./mydock config validate <file>   # Validate config file
./mydock config edit <name>       # Edit config in $EDITOR
./mydock config copy <src> <dst>  # Duplicate config
./mydock config diff <cfg1> <cfg2> # Compare configs
```

## Implementation Priority

### Phase 1: Core Improvements (High Priority)
1. **Host User Mirroring** - Critical for development workflow
   - Auto-detect host user UID/GID/username
   - Create matching user in container
   - Auto-generate volume mounts with matching paths
   - Support for multiple directory mappings
   
2. **Network Management** - Addresses immediate need
   - Implement basic network commands
   - Add network config file support
   - Auto-create networks if specified

3. **Interactive Shell - Basic** - Improves usability
   - Command loop with prompt
   - Basic command execution
   - Config switching
   - Exit/quit commands

### Phase 2: Enhanced Features (Medium Priority)
4. **Host User Mirroring - Advanced**
   - Pattern-based directory discovery
   - Selective read-only mounts
   - Group membership mirroring
   - SSH key and git config sharing
   
5. **Network Templates** - Reusable network configs

6. **Interactive Shell - Advanced** - Better UX
   - Tab completion
   - Command history
   - Colored output
   
7. **Volume Management** - Common operations

8. **Enhanced Monitoring** - Better observability

### Phase 3: Advanced Features (Lower Priority)
9. **Multi-Container Management** - Complex scenarios
10. **Backup/Restore** - Data management
11. **Configuration Management** - Advanced config handling

## Technical Considerations

### Code Organization
Refactor `mydock` into multiple files for maintainability:
```
mydock                  # Main script
lib/
  core.sh              # Core functions
  network.sh           # Network management
  volume.sh            # Volume management
  interactive.sh       # Interactive shell
  config.sh            # Config management
  utils.sh             # Utility functions
```

### Backward Compatibility
- Maintain all existing commands and flags
- Existing config files should work without changes
- Add new parameters as optional
- Provide migration guide for new features

### Error Handling
- Improve error messages with suggestions
- Add validation for config files
- Check Docker daemon availability
- Verify prerequisites (sudo, docker command)

### Documentation
- Update help text for new commands
- Create detailed README with examples
- Add man page
- Include network configuration examples
- Document interactive mode commands

### Testing
- Create test suite for common operations
- Test with various config files
- Validate network operations
- Test interactive mode edge cases

## Example Workflows

### Workflow 1: Development with host user mirroring
```bash
# Create a dev config file
cat > dev-work.conf << EOF
REPOSITORY=kruskakli/my-debian
TAG=v5
NAME=dev-work
HOSTNAME=devbox

# Enable user mirroring
MIRROR_USER=yes
MIRROR_DIRS=(
  "/home/tobbe/work/git/trunk"
  "/home/tobbe/projects/myapp"
  "/home/tobbe/.gitconfig:ro"
  "/home/tobbe/.ssh:ro"
)
NETWORK_NAME=dev_net
EOF

# Run container with automatic user setup
./mydock run --config dev-work.conf

# The container now has:
# - User 'tobbe' with same UID/GID as host
# - Directories mounted at same paths
# - Git config and SSH keys available (read-only)

# Enter as your mirrored user
./mydock shell --name dev-work
# You're now 'tobbe' in the container, can edit files
# Changes appear immediately on host with correct ownership
```

### Workflow 2: Setting up isolated development network
```bash
# Create network config
cat > dev-network.conf << EOF
NETWORK_NAME=dev_isolated
NETWORK_DRIVER=bridge
NETWORK_SUBNET=172.20.0.0/16
NETWORK_CREATE_IF_MISSING=yes
EOF

# Create and configure container
./mydock network create dev_isolated --driver bridge
./mydock run --config debian.conf
./mydock network connect dev_isolated debian_container
```

### Workflow 3: Interactive session
```bash
./mydock interactive

mydock> use debian.conf
Using config: debian.conf
mydock [debian.conf]> set name dev-test
mydock [debian.conf]> show
Config: debian.conf
  NAME: dev-test
  REPOSITORY: kruskakli/my-debian
  TAG: v5
  ...
mydock [debian.conf]> run --dry-run
sudo docker run -dt --privileged ...
mydock [debian.conf]> run
Container dev-test started
mydock [debian.conf]> shell
root@rune:/#
```

### Workflow 4: Network troubleshooting
```bash
./mydock network list
./mydock network inspect mybridge
./mydock network connect mybridge container1
./mydock shell --name container1
# In container: test connectivity
```

## Benefits

1. **Reduced cognitive load** - Interactive mode eliminates need to remember all flags
2. **Network management** - Simplified network operations without raw docker commands
3. **Improved productivity** - Quick config switching and command repetition
4. **Better organization** - Network templates and profiles for common scenarios
5. **Learning tool** - Dry-run mode helps users understand Docker commands
6. **Consistency** - Standardized configurations across environments

## Next Steps

1. Review and approve this plan
2. Implement Phase 1 features
3. Test with existing workflows
4. Gather feedback
5. Iterate on Phase 2 and 3 based on usage patterns

---

**Document Version:** 1.0  
**Date:** October 10, 2025  
**Author:** Enhancement plan for mydock Docker wrapper script
