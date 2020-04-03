FROM debian:buster
MAINTAINER mark.earl.waite@gmail.com

RUN apt-get update 
RUN apt-get install -y sudo bc openjdk-11-jdk
RUN useradd mysudoer -u @@MYUSERID@@
RUN echo 'mysudoer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
