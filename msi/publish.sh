#!/bin/bash -ex
rsync -avz -e "ssh $SSH_OPTS" "${MSI}" "$PKGSERVER:$MSIDIR/"
sha256sum ${MSI} | sed 's, .*/, ,' > ${MSI_SHASUM}
cat ${MSI_SHASUM}
cat ${MSI_SHASUM} | ssh ${SSH_OPTS} ${PKGSERVER} "cat >> $MSIDIR/SHA256SUMS"