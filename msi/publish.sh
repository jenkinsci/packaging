#!/bin/bash -ex
sha256sum ${MSI} | sed 's, .*/, ,' > ${MSI_SHASUM}
cat ${MSI_SHASUM}
rsync -avz -e "ssh $SSH_OPTS" "$MSI" "$MSI_SHASUM" "$PKGSERVER:$MSIDIR/"
