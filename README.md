# mydock

Docker container management wrapper with interactive shell and user mirroring.

## Quick Start

Interactive mode (recommended):
```bash
./mydock
mydock> wizard          # Create a config file
mydock> use myapp.conf  # Load config
mydock> run             # Create and start container
mydock> shell           # Enter container
```

Direct commands:
```bash
./mydock --config myapp.conf run
./mydock --config myapp.conf shell
```

## Features

- Interactive shell mode - REPL environment for managing containers
- User mirroring - Automatic UID/GID matching between host and container
- Configuration wizard - Guided setup for creating config files
- Network management - Built-in Docker network operations
- Config file based - Reusable container definitions

## Configuration

Config files are stored in `conf/` directory. Example:

```bash
# conf/myapp.conf
REPOSITORY=debian
TAG=latest
NAME=myapp
HOSTNAME=myapp
SHARED_DIR=/home/user/projects

# User mirroring (optional)
MIRROR_USER=yes
MIRROR_DIRS=(
  "/home/user/projects"
  "/home/user/.gitconfig:ro"
  "/home/user/.ssh:ro"
)

# Networking (optional)
NETWORK_NAME=mynetwork
PORTS=8080:8080
```

## Interactive Mode

Run `./mydock` without arguments to enter interactive mode.

**Configuration:**
- `use <config>` - Load config file
- `configs` - List available configs
- `wizard` - Create new config (full)
- `quick` - Create config (3 questions)
- `show` - Display current config
- `set <param> <value>` - Override config value

**Container Operations:**
- `run [--dry-run]` - Create and start container
- `start [name]` - Start container (uses config if no name given)
- `stop [name]` - Stop container
- `rm [name]` - Remove container
- `shell [name]` - Enter container shell
- `user [name] [username]` - Enter as user
- `logs [name]` - Show container logs
- `sync [name]` - Commit container to image

**Info:**
- `ps` - List containers
- `images` - List images
- `network <cmd>` - Network operations

## Command Line Usage

```bash
# Container operations
./mydock run --config myapp.conf
./mydock start --name myapp
./mydock stop --name myapp
./mydock shell --name myapp
./mydock rm --name myapp

# User operations
./mydock user --name myapp --user alice
./mydock setup_mirror --name myapp
./mydock setup_users --users users.csv --name myapp

# Info
./mydock ps
./mydock images
./mydock show_config --config myapp.conf

# Build
./mydock build --docker-file Dockerfile

# Dry run
./mydock run --config myapp.conf --dry-run
```

## User Mirroring

Automatically creates a user in the container matching your host user (UID/GID).
Files edited in the container have correct ownership on the host.

Enable in config:
```bash
MIRROR_USER=yes
MIRROR_DIRS=(
  "/home/user/work"
  "/home/user/.gitconfig:ro"
)
```

Or use flag:
```bash
./mydock run --mirror-user
```

Setup in existing container:
```bash
./mydock setup_mirror --name mycontainer
```

## Setup Multiple Users

Create CSV file (Username,UID,Groupname,GID):
```csv
rune,1002,rune,1002
gunnar,1003,gunnar,1003
```

Run command:
```bash
./mydock setup_users --users users.csv --name mycontainer --dry-run
./mydock setup_users --users users.csv --name mycontainer
```

Verify:
```bash
./mydock user --name mycontainer --user gunnar
```

## Network Management

Networks must be configured in the config file for `network create`:
```bash
# In config file
NETWORK_NAME=mynetwork
NETWORK_DRIVER=bridge          # Optional, default: bridge
NETWORK_SUBNET=172.18.0.0/16   # Optional
NETWORK_GATEWAY=172.18.0.1     # Optional
NETWORK_CREATE_IF_MISSING=yes  # Auto-create if missing
```

Interactive mode:
```bash
mydock> use mynetwork.conf
mydock> network create                    # Creates network from config
mydock> network list                      # List all networks
mydock> network inspect mynetwork         # Show network details
mydock> network connect mynetwork myapp   # Connect container to network
mydock> network disconnect mynetwork myapp
mydock> network rm mynetwork              # Remove network
```

Command line:
```bash
./mydock --config myapp.conf run  # Auto-creates network if NETWORK_CREATE_IF_MISSING=yes
```

## Examples

### Development Container
```bash
./mydock
mydock> wizard
# Follow prompts to create dev.conf
mydock> use dev.conf
mydock> run
mydock> shell
```

### Quick Setup
```bash
./mydock
mydock> quick
# Answer 3 questions: image, name, directory
mydock> run
```

## Options

```
-h, --help              Show help
-v, --verbose           Verbose output
-n, --name <name>       Container name
--tag <tag>             Image tag
-u, --user <user>       Username
-p, --ports <ports>     Port mapping
--config <file>         Config file
--docker-file <file>    Dockerfile for build
--network <name>        Network name
--mirror-user           Enable user mirroring
--dry-run               Show command without executing
```
