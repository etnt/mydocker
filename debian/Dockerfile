# Use the Debian testing slim image as the base
FROM debian:testing-slim

# Install sudo, git, and tmux
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    tmux


# Create a group and user 'tobbe' with UID and GID of 1002
RUN groupadd -f -g 1002 tobbe && \
    useradd -m -u 1002 -g 1002 tobbe -s /bin/bash

# Configure sudoers for the 'tobbe' user
RUN echo 'tobbe ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tobbe && \
    chmod 0440 /etc/sudoers.d/tobbe

# Switch to your new user in the docker image
USER tobbe

# Set the working directory (optional)
WORKDIR /home/tobbe
