FROM centos:7
LABEL project="https://github.com/jenkinsci/packaging"

ARG USER_ID

RUN yum upgrade -y && yum install -y sudo initscripts bc curl which java-1.8.0-openjdk
RUN useradd mysudoer -u ${USER_ID}
RUN echo 'mysudoer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN sed -i 's/requiretty/!requiretty/g' /etc/sudoers
