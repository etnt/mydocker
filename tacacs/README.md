# Setup a TACACS server as a docker container

See: https://github.com/ygorelik/tacacs-auth

## Get the docker image

    git pull llima3000/tacplus


## Setup tacacs_client

    virtualenv env
    env/bin/pip install tacacs_plus
    [ -f env/bin/tacacs_client ] && echo exists

## Setup with mydock

Prepare directories:

    mkdir /tmp/tacacs
    cp tacacs/tac_plus.conf /tmp/tacacs/.

Create and start container:

    ./mydock run --config tacacs.conf
    
Check log output:

    tail /tmp/tacacs/logs/tac_plus/tac_plus.log

Run the Client (then check the log output again):

    env/bin/tacacs_client -v -H 127.0.0.1 -p 4049 -k tacacs123 -u tacadmin authenticate --password tacadmin




## Setup without mydock

See:

https://github.com/ygorelik/tacacs-auth/blob/master/resources/README-building-test-tacacs-docker.md

Run:

    mkdir -p ./logs/tac_plus
    
    docker run -td --name tacplus \
    -v ${PWD}/tac_plus.conf:/etc/tacacs+/tac_plus.conf \
    -v ${PWD}/logs/tac_plus:/var/log \
    -p 4049:49 \
    -e DEBUGLEVEL=16 \
    llima3000/tacplus
    
    env/bin/pip install tacacs_plus
    
    env/bin/tacacs_client -v -H 127.0.0.1 -p 4049 -k tacacs123 -u tacadmin authenticate --password tacadmin
    
    tail logs/tac_plus/tac_plus.log
    
