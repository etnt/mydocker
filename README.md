# HOW TO USE THE mydock SCRIPT

This is a simple script on top of all those docker commands
that I never can remember (OTOH, now I need to remember how
the `mydock` script is used... :-P ).

A container repository offers storage for container images.
Container images are used to create new containers in runtime
based on preset definitions established in the image itself.

`mydock` make use of a simple config file, containing some
basic info to be used by the `mydock` commands. If no 
`--config <file>` is given the `default.conf` file is used:

    > cat default.conf
    REPOSITORY=containers.cisco.com/ttornkvi/debian-bullseye-v2
    TAG=v3
    NAME=nils
    SHARED_DIR=/tmp/shared_docker_dir
    HOSTNAME=arnold
    
For all `mydock` commands you can use the `--dry-run` switch
to see what the resulting docker command looks like without
actually executing it.

## Build a docker image

    # Build an image based on the (default) `Dockerfile` file
    > mydock build
    
    # Build an image based on the specified dockerfile file
    > mydock build --docker-file Dockerfile.bullseye
    
    # As above but use a specified config file
    > mydock build --config my.conf --docker-file Dockerfile.bullseye

## Start/Stop/Remove a (new) container based on an image

    # Start a new container, making use of the default.conf settings
    > mydock run
    
    # Start a new container; give the container an explicit name
    > mydock run --name bill

    # Stop a container identified by a name
    > mydock stop --name bill

    # Start an existing, named, container
    > mydock start --name bill

    # Remove a named container
    > mydock rm --name bill

## Show some info about available images and containers

    > mydock show

## Commit (store permanently) a container

When you have made any changes in your container that you want to
store as a new, tagged, image version.

    # Use the default.conf settings with the TAG=latest
    > mydock sync 

    # Use the default.conf settings with an explicit TAG
    > mydock sync --tag v7


## Setup Users in the Container

So setup one or several User accounts in your container,
create a CSV file containing the Username/Userid/Groupname/Groupid:

    ❯ cat users.conf 
    rune,1002,rune,1002
    gunnar,1003,gunnar,1003 

Run the command `setup_users`, verify first with `--dry-run`:

    ❯ ./mydock setup_users --dry-run --users users.conf
    USERNAME             USERID     GROUPNAME            GROUPID
    rune                 1002       rune                 1002
    sudo docker exec -u root nils bash -c groupadd -f -g 1002 rune
    sudo docker exec -u root nils bash -c useradd -m -u 1002 -g 1002 rune -s /bin/bash
    sudo docker exec -u root nils bash -c echo 'rune  ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/rune
    --- 
    gunnar               1003       gunnar               1003
    sudo docker exec -u root nils bash -c groupadd -f -g 1003 gunnas
    sudo docker exec -u root nils bash -c useradd -m -u 1003 -g 1003 gunnar -s /bin/bash
    sudo docker exec -u root nils bash -c echo 'gunnar  ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/gunnar

If it looks good, run the command without `--dry-run`.

Verify that you can login as one of the users and that it can become root:

    ❯ ./mydock user --user gunnar
    sudo docker exec -u root -it nils bash -c su -l gunnar
    gunnar@arnold:~$ sudo bash
    root@arnold:/home/gunnar#





## Random Notes

To install docker on Linux Mint:

 https://gist.github.com/sirkkalap/e87cd580a47b180a7d32[A

curl -sSL https://gist.githubusercontent.com/sirkkalap/e87cd580a47b180a7d32/raw/d9c9ebae4f5cf64eed4676e8aedac265b5a51bfa/Install-Docker-on-Linux-Mint.sh | bash -x

