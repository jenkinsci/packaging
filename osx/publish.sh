#!/bin/bash -ex
rsync -avz -e "$SSH_OPTS" "${OSX}" "$PKGSERVER:$OSXDIR/"
