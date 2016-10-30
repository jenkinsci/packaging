#!/bin/bash -ex
which sha256sum >/dev/null 2>&1 || { echo "sha256sum not found" >&2 ; exit 1 ; }

