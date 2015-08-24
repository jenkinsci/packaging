#!/bin/bash -e
#
# Usage:
#   branding.sh <DIR>
#
# Recursively replace all the branding placeholders by their actual values
# Replace the branding file variables with the contents of the named file
ARGS=()

# Read branding files to environment variables and convert to search and replace args
for t in $(cat $(dirname "$0")/branding-files.list);
do
  # Keep going if file is not set, otherwise it'll hang on 'cat' command
  if [ -n "$t" ]
  then
  	v=""
  else
  	v="$(eval cat \$${t})"	
  fi
  # Escape the @ signs in the variable as they will do bad things in Perl
  v="$(echo $v | sed 's#\@#\\\@#g' )"
  ARGS+=("-e" "s%\@\@${t}\@\@%${v}%g;")
done

# Convert variables to search and replace arguments
for t in $(cat $(dirname "$0")/branding.list);
do
  v="$(eval echo \$${t})"
  # Escape the @ signs in the variable as they will do bad things in Perl
  v="$(echo $v | sed 's#\@#\\\@#g' )"
  ARGS+=("-e" "s%\@\@${t}\@\@%${v}%g;")
done

if [ -f "$1" ]; then
  perl -pi -w "${ARGS[@]}" "$1"
else
  find "$1" -type f -print0 | xargs -0 -t perl -pi -w "${ARGS[@]}"
fi