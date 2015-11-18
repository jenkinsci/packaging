#!/bin/bash

# Build fast OS docker images that run slower steps ahead of time, to save time running tests

docker build -t sudo-debian:wheezy sudo-debian
docker build -t sudo-centos:6 sudo-centos6
docker build -t sudo-centos:7 sudo-centos7
docker build -t sudo-opensuse:13.2 sudo-opensuse
docker build -t sudo-ubuntu:14.04 sudo-ubuntu14
docker build -t sudo-ubuntu:15.10 sudo-ubuntu15