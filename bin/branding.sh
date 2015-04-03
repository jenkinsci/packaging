#!/bin/bash
#
# Usage:
#   branding.sh <DIR>
#
# Recursively replace all the branding placeholders by their actual values
exec perl -pi -w \
  -e "s/\@\@ARTIFACTNAME\@\@/${ARTIFACTNAME}/g;" \
  -e "s/\@\@CAMELARTIFACTNAME\@\@/${CAMELARTIFACTNAME}/g;" \
  -e "s/\@\@PRODUCTNAME\@\@/${PRODUCTNAME}/g;" \
  -e "s/\@\@VENDOR\@\@/${VENDOR}/g;" \
  -e "s/\@\@SUMMARY\@\@/${SUMMARY}/g;" \
  -e "s/\@\@PORT\@\@/${PORT}/g;" \
  $(find "$1" -type f)
