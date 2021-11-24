#!/bin/sh
#
# Copyright (c) 2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

npm install -g @eclipse-che/che-theia-devworkspace-handler@0.0.1-1637592995
mkdir /build/out/
for dir in /build/devfiles/*/
do
  devfile=$(cat ${dir}meta.yaml | grep "v2:")
  if [ -n "$devfile" ]; then
    dir=${dir%/}
    dir=/build/out/${dir##*/}
    mkdir ${dir}
    npx @eclipse-che/che-theia-devworkspace-handler --devfile-url:${devfile##*v2: } --output-file:${dir}/devworkspace.yaml
  fi
done
