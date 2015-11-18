FROM opensuse:13.2
MAINTAINER samvanoort@gmail.com

RUN zypper --non-interactive in sudo
RUN useradd mysudoer -u @@MYUSERID@@
RUN echo 'mysudoer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
