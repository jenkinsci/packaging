# #!/bin/bash -ex
# set -o pipefail
# sha256sum ${MSI} | sed 's, .*/, ,' > ${MSI_SHASUM}
# cat ${MSI_SHASUM}
# ssh $SSH_OPTS $PKGSERVER mkdir -p "'$MSIDIR/'"
# rsync -avz -e "ssh $SSH_OPTS" "$MSI" "$MSI_SHASUM" "$PKGSERVER:$MSIDIR/"
