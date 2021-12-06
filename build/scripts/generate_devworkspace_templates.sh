#!/bin/sh
#
# Copyright (c) 2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

npm install -g @eclipse-che/che-theia-devworkspace-handler@0.0.1-1638274327
mkdir /build/out/
for dir in /build/devfiles/*/
do
  devfile=$(grep "v2:" "${dir}"meta.yaml)
  if [ -n "$devfile" ]; then
    devfile=${devfile##*v2: }
    npx @eclipse-che/che-theia-devworkspace-handler --devfile-url:"${devfile}" --output-file:"${dir}"/devworkspace-che-theia-next.yaml
    npx @eclipse-che/che-theia-devworkspace-handler --devfile-url:"${devfile}" --editor:eclipse/che-theia/latest \
    --output-file:"${dir}"/devworkspace-che-theia-latest.yaml
  fi
done
