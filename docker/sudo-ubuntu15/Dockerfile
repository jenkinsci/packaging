FROM ubuntu:15.10
MAINTAINER samvanoort@gmail.com

RUN apt-get update 
RUN apt-get install -y sudo bc
RUN useradd mysudoer -u @@MYUSERID@@
RUN echo 'mysudoer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
