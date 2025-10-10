#!/usr/bin/env bash
#
# Setup mirrored user in ConfD 8.0 development container
# This script creates a user matching your host user for seamless file editing
#

set -e

CONTAINER_NAME="confd-8-0-dev"
HOST_USER="tobbe"
HOST_UID=1000
HOST_GID=1000
HOST_GROUPS="sudo,docker"

echo "Setting up user ${HOST_USER} (UID:${HOST_UID}, GID:${HOST_GID}) in container ${CONTAINER_NAME}..."

# Create the group if it doesn't exist
sudo docker exec -u root ${CONTAINER_NAME} bash -c "groupadd -f -g ${HOST_GID} ${HOST_USER}" 2>/dev/null || true

# Create the user if it doesn't exist
sudo docker exec -u root ${CONTAINER_NAME} bash -c "id ${HOST_USER} &>/dev/null || useradd -m -u ${HOST_UID} -g ${HOST_GID} ${HOST_USER} -s /bin/bash"

# Add to sudo group and configure passwordless sudo
sudo docker exec -u root ${CONTAINER_NAME} bash -c "usermod -aG sudo ${HOST_USER} 2>/dev/null || true"
sudo docker exec -u root ${CONTAINER_NAME} bash -c "echo '${HOST_USER}  ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${HOST_USER}"

# Ensure the work directory exists and has correct permissions
sudo docker exec -u root ${CONTAINER_NAME} bash -c "mkdir -p /home/tobbe/work/git/confd-8.0"
sudo docker exec -u root ${CONTAINER_NAME} bash -c "chown -R ${HOST_UID}:${HOST_GID} /home/tobbe"

echo "User setup complete!"
echo ""
echo "You can now enter the container as your user:"
echo "  ./mydock user --name ${CONTAINER_NAME} --user ${HOST_USER}"
echo ""
echo "Or use the shell command and then switch user:"
echo "  ./mydock shell --name ${CONTAINER_NAME}"
echo "  su - ${HOST_USER}"
