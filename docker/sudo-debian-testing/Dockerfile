FROM debian:bullseye
LABEL project="https://github.com/jenkinsci/packaging"

ARG USER_ID

RUN apt-get update && apt-get upgrade --assume-yes && apt-get install --assume-yes sudo bc curl default-jdk && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN useradd mysudoer -u ${USER_ID}
RUN echo 'mysudoer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
