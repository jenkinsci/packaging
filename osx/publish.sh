#!/bin/bash -ex
rsync -avz -e "ssh $SSH_OPTS" "${OSX}" "$PKGSERVER:$OSXDIR/"
sha256sum ${OSX} | sed 's, .*/, ,' > ${OSX_SHASUM}
cat ${OSX_SHASUM}
cat ${OSX_SHASUM} | ssh ${SSH_OPTS} ${PKGSERVER} "cat >> $OSXDIR/SHA256SUMS"