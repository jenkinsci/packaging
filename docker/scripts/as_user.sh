#!/bin/bash
# Author Sam Van Oort

# Sets up a user & group on the fly and runs as them within the container, adding them as a sudoer
# Use case: you are using docker for disposable environments mounting a local folder as a volume
#   and need to be able to use the same image with multiple users

# Usage: 
#  Interactive mode:
# docker run -h DOCKER -it --rm -v $(pwd):/localmount -w /localmount my-container-name as_user.sh $(id -un) $(id -u) $(id -gn) $(id -g)

#  Run single command mode
# docker run --rm -v "$(pwd)":/localmount -w /localmount my-container-name as_user.sh $(id -un) $(id -u) $(id -gn) $(id -g) "Echo 'do something' "

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
    echo 'Create user and group and switch to them'
    echo 'Arguments: are username userid groupname groupid'
    echo 'At least one is missing!'
    exit 1
else
    addgroup "$3" --gid "$4" || true
    useradd "$1" -m -u "$2" -g "$3" || true
    echo "$1 ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

    # 5th argument is a command string to run with that user
    if [ -z "$5" ]; then 
        su $1 -m /bin/bash 
    else 
        su $1 -s /bin/bash -c "$5" 
    fi
fi