FROM centos:7
MAINTAINER mark.earl.waite@gmail.com

RUN yum install -y sudo initscripts bc which java-1.8.0-openjdk
RUN useradd mysudoer -u @@MYUSERID@@
RUN echo 'mysudoer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN sed -i 's/requiretty/!requiretty/g' /etc/sudoers
