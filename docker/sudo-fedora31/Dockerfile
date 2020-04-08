FROM fedora:31
LABEL project="https://github.com/jenkinsci/packaging"

RUN dnf upgrade -y && dnf install -y bc chkconfig curl java-11-openjdk-devel which
RUN rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
