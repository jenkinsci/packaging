FROM centos:centos6.9
MAINTAINER mark.earl.waite@gmail.com

RUN yum install -y sudo bc which
RUN useradd mysudoer -u @@MYUSERID@@
RUN echo 'mysudoer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN sed -i 's/requiretty/!requiretty/g' /etc/sudoers
