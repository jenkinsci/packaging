#!/bin/bash -ex
rsync -avz -e "ssh $SSH_OPTS" "${OSX}" "$PKGSERVER:$OSXDIR/"
