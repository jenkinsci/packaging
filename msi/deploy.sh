#!/bin/bash -ex
rsync -avz "$MSI" "$PKGSERVER:$MSIDIR/"
