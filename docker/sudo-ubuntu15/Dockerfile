FROM ubuntu:15.10
MAINTAINER samvanoort@gmail.com

RUN apt-get update 
RUN apt-get install -y sudo
RUN useradd --gecos '' -u @@MYUSERID@@ mysudoer
RUN useradd mysudoer sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
