#!/bin/bash -ex
#
# Usage:
#   branding.sh <DIR>
#
# Recursively replace all the branding placeholders by their actual values
ARGS=()

for t in $(cat $(dirname "$0")/branding.list);
do
  v="$(eval echo \$${t})"
  ARGS+=("-e" "s%\@\@${t}\@\@%${v}%g;")
done

exec perl -pi -w "${ARGS[@]}" $(find "$1" -type f)
