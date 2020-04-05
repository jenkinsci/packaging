#!/bin/bash

# Build fast OS docker images that run slower steps ahead of time, to save time running tests
# Note: this modifies the original Dockerfiles so the current user can sudo

cd "$(dirname "$0")"
docker build --build-arg USER_ID=$(id -u ${USER}) -t sudo-debian:stable sudo-debian
docker build --build-arg USER_ID=$(id -u ${USER}) -t sudo-debian:testing sudo-debian-testing
# docker build --build-arg USER_ID=$(id -u ${USER}) -t sudo-opensuse:15.1 sudo-opensuse
docker build --build-arg USER_ID=$(id -u ${USER}) -t sudo-ubuntu:18.04  sudo-ubuntu18
docker build --build-arg USER_ID=$(id -u ${USER}) -t sudo-ubuntu:19.10  sudo-ubuntu19
