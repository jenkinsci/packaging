#!/bin/bash

# Build fast OS docker images that run slower steps ahead of time, to save time running tests

docker build -t fast-debian:wheezy fast-debian
docker build -t fast-centos:6 fast-centos6
docker build -t fast-centos:7 fast-centos7
docker build -t fast-opensuse:13.2 fast-opensuse