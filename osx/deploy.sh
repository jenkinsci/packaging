#!/bin/bash -ex
rsync -avz "${OSX}" "$PKGSERVER:$OSXDIR/"
