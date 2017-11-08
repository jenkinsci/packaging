FROM ubuntu:14.04
MAINTAINER svanoort <samvanoort@gmail.com>

# User id of the build user
ARG uid=1000
ENV uid $uid

# Group id of the build user
ARG gid=1000
ENV gid $gid

RUN groupadd jenkins -g $gid && useradd jenkins -u $uid -g $gid -m -d /home/jenkins

# Dependencies plus vim for convenience, wget if you're trying to get fancy
RUN apt-get update \
  && apt-get install -y make unzip devscripts debhelper rpm expect createrepo ruby maven openjdk-7-jre \
  && apt-get install -y vim git \
  && apt-get install -y wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Requirement, note that v2 or later runs into issues with gem install due to Ruby 2 req
RUN gem install net-sftp -v 1.1.1
COPY scripts/as_user.sh /bin/as_user.sh