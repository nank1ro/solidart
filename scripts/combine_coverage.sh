#!/usr/bin/env bash

escapedPath="$(echo `pwd` | sed 's/\//\\\//g')"

# flutter
if grep flutter pubspec.yaml > /dev/null; then
  if [ -d "coverage" ]; then
    # combine line coverage info from package tests to a common file
    sed "s/^SF:lib/SF:$escapedPath\/lib/g" coverage/lcov.info >> "$MELOS_ROOT_PATH/lcov.info"
    rm -rf "coverage"
  fi
else
  # pure dart
  if [ -d "coverage" ]; then
    # combine line coverage info from package tests to a common file
    sed "s/^SF:lib/SF:$escapedPath\/lib/g" coverage/lcov.info >> "$MELOS_ROOT_PATH/lcov.info"
    rm -rf "coverage"
  fi
fi
