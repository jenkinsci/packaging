#!/bin/bash -e
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

if [ -f "$1" ]; then
  perl -pi -w "${ARGS[@]}" "$1"
else
  find "$1" -type f -print0 | xargs -0 -t perl -pi -w "${ARGS[@]}"
fi