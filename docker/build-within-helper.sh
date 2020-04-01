#!/bin/bash

# Runs the packaging container as the local user, mounting the local folder to /localmount and setting it as workspace
# Also creates the user and does the needful for them

if [ -z "$1" ]; then 
    echo "Usage: bash build-within-helper.sh $command"
else
    docker run --rm -v "$(pwd)":/localmount -w /localmount jenkins-packaging-builder:0.3 as_user.sh $(id -un) $(id -u) $(id -gn) $(id -g) "$1"
fi
