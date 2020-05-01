#!/bin/bash

# Build fast OS docker images that run slower steps ahead of time, to save time running tests
# Note: this modifies the original Dockerfiles so the current user can sudo

cd "$(dirname "$0")"
docker build                                      -t sudo-centos:7 sudo-centos7
docker build --build-arg USER_ID=$(id -u ${USER}) -t sudo-debian:stable sudo-debian
docker build --build-arg USER_ID=$(id -u ${USER}) -t sudo-debian:oldstable sudo-debian-oldstable
docker build --build-arg USER_ID=$(id -u ${USER}) -t sudo-debian:testing sudo-debian-testing
docker build --build-arg USER_ID=$(id -u ${USER}) -t sudo-opensuse:15.1 sudo-opensuse
docker build                                      -t sudo-fedora:31 sudo-fedora31
docker build --build-arg USER_ID=$(id -u ${USER}) -t sudo-ubuntu:16.04  sudo-ubuntu16
docker build --build-arg USER_ID=$(id -u ${USER}) -t sudo-ubuntu:18.04  sudo-ubuntu18
docker build --build-arg USER_ID=$(id -u ${USER}) -t sudo-ubuntu:19.10  sudo-ubuntu19
docker build --build-arg USER_ID=$(id -u ${USER}) -t sudo-ubuntu:20.04  sudo-ubuntu20
