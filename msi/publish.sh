#!/bin/bash -ex
rsync -avz -e "ssh $SSH_OPTS" "$MSI" "$PKGSERVER:$MSIDIR/"
