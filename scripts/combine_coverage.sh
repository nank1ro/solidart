#!/usr/bin/env bash

escapedPath="$(echo `pwd` | sed 's/\//\\\//g')"

# combine line coverage info from package tests to a common file
sed "s/^SF:lib/SF:$escapedPath\/lib/g" coverage/lcov.info >> "$MELOS_ROOT_PATH/lcov.info"
rm -rf "coverage"
