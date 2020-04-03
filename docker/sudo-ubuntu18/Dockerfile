FROM ubuntu:18.04
MAINTAINER mark.earl.waite@gmail.com

RUN apt-get update 
RUN apt-get install -y sudo bc default-jdk
RUN useradd mysudoer -u @@MYUSERID@@
RUN echo 'mysudoer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
