FROM centos:6
MAINTAINER samvanoort@gmail.com

RUN yum install -y sudo bc which
RUN useradd mysudoer -u @@MYUSERID@@
RUN echo 'mysudoer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN sed -i 's/requiretty/!requiretty/g' /etc/sudoers
