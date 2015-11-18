FROM opensuse:13.2
MAINTAINER samvanoort@gmail.com

RUN zypper --non-interactive in sudo
RUN useradd -u @@MYUSERID@@ mysudoer
RUN useradd mysudoer sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers