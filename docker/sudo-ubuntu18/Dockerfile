FROM ubuntu:18.04
MAINTAINER mark.earl.waite@gmail.com

ARG USER_ID

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y sudo bc curl default-jdk
RUN useradd mysudoer -u ${USER_ID}
RUN echo 'mysudoer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
