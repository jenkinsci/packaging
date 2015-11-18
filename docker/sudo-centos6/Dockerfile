FROM centos:6
MAINTAINER samvanoort@gmail.com

RUN yum install -y sudo
RUN useradd --disabled-password --gecos '' -u @@MYUSERID@@ mysudoer
RUN useradd mysudoer sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers