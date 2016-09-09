#!/bin/bash
lsb_release -rs | awk '{ exit ($1 >= 16.04) }' && \
  echo 'Snaps can only be built on Ubuntu 16.04 or later.' && exit 0
sudo apt-get install -y snapcraft || true

