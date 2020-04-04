FROM centos:7
MAINTAINER mark.earl.waite@gmail.com

ARG USER_ID

RUN yum upgrade -y && yum install -y sudo initscripts bc curl which java-1.8.0-openjdk
RUN useradd mysudoer -u ${USER_ID}
RUN echo 'mysudoer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN sed -i 's/requiretty/!requiretty/g' /etc/sudoers
