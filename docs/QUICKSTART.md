# Quick Start Guide - mydock Phase 1

## Try It Now!

### Test 1: User Mirroring with ConfD Container

```bash
# Preview what will happen (dry-run)
./mydock-new run --config confd-8.0-dev.conf --dry-run

# Create the container with automatic user setup
./mydock-new run --config confd-8.0-dev.conf

# Enter the container as your mirrored user
./mydock-new user --name confd-8-0-dev --user tobbe

# Inside container, verify:
whoami              # Should show: tobbe
id                  # Should show: uid=1000(tobbe) gid=1000(tobbe)
cd ~/work/git/confd-8.0
touch test-file.txt
ls -la test-file.txt  # Should be owned by tobbe:tobbe

# Exit container and check on host
exit
ls -la /home/tobbe/work/git/confd-8.0/test-file.txt
# Should be owned by tobbe:tobbe!
```

### Test 2: Interactive Mode

```bash
./mydock-new interactive

# Inside interactive mode:
mydock> configs                    # List available configs
mydock> use confd-8.0-dev.conf    # Load config
mydock> show                       # View settings
mydock> ps                         # See containers
mydock> attach confd-8-0-dev      # Set active container
mydock> shell                      # Enter container
# (inside container, type 'exit' to return)
mydock> exit                       # Leave interactive mode
```

### Test 3: Network Management

```bash
# List existing networks
./mydock-new network list

# Create a development network config
cat > test-network.conf << 'EOF'
REPOSITORY=debian
TAG=latest
NAME=network-test
SHARED_DIR=/tmp/test
NETWORK_NAME=test_network
NETWORK_DRIVER=bridge
NETWORK_CREATE_IF_MISSING=yes
EOF

# Run container (network auto-created)
./mydock-new run --config test-network.conf --dry-run

# Inspect the network
./mydock-new network inspect test_network

# Connect another container
./mydock-new network connect test_network another-container
```

### Test 4: Compare Old vs New

```bash
# Old way
./mydock run --config confd-8.0-dev.conf --dry-run

# New way (with user mirroring)
./mydock-new run --config confd-8.0-dev.conf --dry-run

# Notice the difference:
# - Additional volume mounts for mirrored directories
# - User auto-setup happens after container starts
```

### Test 5: View Enhanced Configuration

```bash
# Show detailed config including new features
./mydock-new show_config --config confd-8.0-dev.conf

# Should show:
# - Container settings
# - User mirroring configuration
# - Mounted directories
```

## What to Look For

### ✅ Success Indicators

1. **User Mirroring:**
   - Container has user `tobbe` with UID 1000, GID 1000
   - Files created in container appear on host with correct ownership
   - No permission denied errors when editing files

2. **Network Management:**
   - Networks can be listed, created, inspected
   - Containers can connect to custom networks
   - Auto-create works when configured

3. **Interactive Mode:**
   - Prompt shows current config and container
   - Commands execute without full syntax
   - History works (up arrow)

4. **Enhanced Output:**
   - Colored messages (✓, ✗, ℹ, ⚠)
   - Clear success/error indicators
   - Helpful feedback messages

### ❌ Issues to Watch For

1. Permission errors when accessing mounted directories
2. UID/GID mismatch between host and container
3. Network creation failures
4. Interactive mode command parsing errors
5. Regressions in existing functionality

## Comparison: Before vs After

### Before (Original mydock)

```bash
# Manual setup required
./mydock run --config confd-8.0-dev.conf
./mydock shell --name confd-8-0-dev
# Inside container:
groupadd -f -g 1000 tobbe
useradd -m -u 1000 -g 1000 tobbe -s /bin/bash
usermod -aG sudo tobbe
echo 'tobbe ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tobbe
exit
./mydock user --name confd-8-0-dev --user tobbe
```

### After (Phase 1)

```bash
# Automatic!
./mydock-new run --config confd-8.0-dev.conf
./mydock-new user --name confd-8-0-dev --user tobbe
# User already exists with correct UID/GID!
```

## Troubleshooting

### Container won't start
```bash
# Check docker is running
sudo systemctl status docker

# Check for name conflicts
./mydock-new ps
# Remove old container if needed
./mydock-new rm --name confd-8-0-dev
```

### User not created
```bash
# Manually setup user in existing container
./mydock-new setup_mirror --name confd-8-0-dev

# Verify
./mydock-new shell --name confd-8-0-dev
id tobbe
```

### Network errors
```bash
# List networks to check status
./mydock-new network list

# Remove problematic network
./mydock-new network remove test_network

# Try again
```

### Interactive mode not working
```bash
# Check bash version (needs 4.0+)
bash --version

# Run with verbose mode
./mydock-new -v interactive
```

## Clean Up After Testing

```bash
# Stop and remove test containers
./mydock-new stop --name confd-8-0-dev
./mydock-new rm --name confd-8-0-dev

# Remove test networks
./mydock-new network remove test_network

# Remove test files
rm -f /home/tobbe/work/git/confd-8.0/test-file.txt
```

## Next Steps After Testing

1. Report any issues found
2. Suggest improvements
3. Test with your actual workflows
4. When ready, replace old `mydock`:
   ```bash
   mv mydock mydock-backup
   mv mydock-new mydock
   ```

## Getting Help

- Read `PHASE1-README.md` for detailed documentation
- Check `PHASE1-SUMMARY.md` for implementation details
- View `ENHANCEMENT_PLAN.md` for future roadmap
- Run `./mydock-new --help` for command reference
