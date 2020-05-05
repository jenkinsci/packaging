FROM opensuse/leap:15.1
LABEL project="https://github.com/jenkinsci/packaging"

ARG USER_ID

# Install latest operating system updates - prefer to test updated operating system
RUN zypper --non-interactive update

# For some reason the base docker image doesn't include chkconfig
# So we install aaa_base for that and vim for tests and because it
# conveniently pulls in required perl deps needed for chkconfig too!
RUN zypper --non-interactive install sudo aaa_base vim bc curl which java-1_8_0-openjdk-devel
RUN useradd mysudoer -u ${USER_ID}
RUN echo 'mysudoer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
