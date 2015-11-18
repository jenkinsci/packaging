FROM ubuntu:14.04
MAINTAINER samvanoort@gmail.com

RUN apt-get update 
RUN apt-get install -y sudo
RUN useradd mysudoer -u @@MYUSERID@@
RUN echo 'mysudoer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
