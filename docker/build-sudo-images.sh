#!/bin/bash

# Build fast OS docker images that run slower steps ahead of time, to save time running tests
# Note: this modifies the original Dockerfiles so the current user can sudo

cd "$(dirname "$0")"
sed -i.orig -e "s#@@MYUSERID@@#`id -u`#g" sudo-*/Dockerfile
docker build -t sudo-debian:buster sudo-debian
docker build -t sudo-centos:6 sudo-centos6
docker build -t sudo-centos:7 sudo-centos7
docker build -t sudo-opensuse:15.1 sudo-opensuse
docker build -t sudo-ubuntu:18.04 sudo-ubuntu18
docker build -t sudo-ubuntu:19.10 sudo-ubuntu19
