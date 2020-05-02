FROM fedora:32
LABEL project="https://github.com/jenkinsci/packaging"

# Intentionally testing default Java on current Fedora release.
# Default Java is currently Java 8.  When that changes in a future
# Fedora release, this will need to be changed.
RUN dnf upgrade -y && dnf install -y bc chkconfig curl java which
