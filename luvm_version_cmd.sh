#!/bin/bash
# Luvit Version Manager
# Implemented as a bash function
# To use source this file from your bash profile
#
# Expand a version using the version cache
luvm_version()
{
  PATTERN=$1
  VERSION=''
  if [ -f "$LUVM_DIR/alias/$PATTERN" ]; then
    luvm_version `cat $LUVM_DIR/alias/$PATTERN`
    return
  fi
  # If it looks like an explicit version, don't do anything funny
  if [[ "$PATTERN" == ?*.?*.?* ]]; then
    VERSION="$PATTERN"
  fi
  # The default version is the current one
  if [ ! "$PATTERN" -o "$PATTERN" = 'current' ]; then
    VERSION=`luvit -v 2>/dev/null`
  fi
  if [ "$PATTERN" = 'all' ]; then
    (cd $LUVM_DIR; \ls -dG v* 2>/dev/null || echo "N/A")
    return
  fi
  if [ ! "$VERSION" ]; then
    VERSION=`(cd $LUVM_DIR; \ls -d ${PATTERN}* 2>/dev/null) | sort -t. -k 2,1n -k 2,2n -k 3,3n | tail -n1`
  fi
  if [ ! "$VERSION" ]; then
    echo "N/A"
    return 13
  elif [ -e "$LUVM_DIR/$VERSION" ]; then
    (cd $LUVM_DIR; \ls -dG "$VERSION")
  else
    echo "$VERSION"
  fi
}

luvm_version $@ 
