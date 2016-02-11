FROM ubuntu:14.04
MAINTAINER svanoort <samvanoort@gmail.com>


# Dependencies plus vim for convenience, wget if you're trying to get fancy
RUN apt-get update \
  && apt-get install -y make unzip devscripts debhelper rpm expect createrepo ruby maven openjdk-7-jre \
  && apt-get install -y vim git \
  && apt-get install -y wget \ 
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Requirement, note that v2 or later runs into issues with gem install due to Ruby 2 req
RUN gem install net-sftp -v 1.1.1

RUN chsh -s /bin/bash root
