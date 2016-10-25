#!/bin/bash -ex -o pipefail
sha256sum ${OSX} | sed 's, .*/, ,' > ${OSX_SHASUM}
cat ${OSX_SHASUM}
rsync -avz -e "ssh $SSH_OPTS" "${OSX}" "${OSX_SHASUM}" "$PKGSERVER:$OSXDIR/"
