#!/bin/bash -ex
set -o pipefail
sha256sum ${OSX} | sed 's, .*/, ,' > ${OSX_SHASUM}
cat ${OSX_SHASUM}
ssh $SSH_OPTS $PKGSERVER mkdir -p "'$OSXDIR/'"
rsync -avz -e "ssh $SSH_OPTS" "${OSX}" "${OSX_SHASUM}" "$PKGSERVER:$OSXDIR/"
