FROM ubuntu:18.04
LABEL project="https://github.com/jenkinsci/packaging"

ARG USER_ID

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y sudo bc curl default-jdk
RUN useradd mysudoer -u ${USER_ID}
RUN echo 'mysudoer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
