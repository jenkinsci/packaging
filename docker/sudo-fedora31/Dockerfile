FROM fedora:31
LABEL project="https://github.com/jenkinsci/packaging"

# Intentionally testing Java 11 on this older Fedora release so that
# the current Fedora release tests the default Java (currently Java 8).
RUN dnf upgrade -y && dnf install -y bc chkconfig curl java-11-openjdk-devel which
