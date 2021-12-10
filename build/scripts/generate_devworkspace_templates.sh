#!/bin/sh
#
# Copyright (c) 2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

VERSION="${1%/}"

npm install -g @eclipse-che/che-theia-devworkspace-handler@0.0.1-1637592995
mkdir /build/out/
for dir in /build/devfiles/*/
do
  devfile=$(grep "v2:" "${dir}"meta.yaml)
  if [ -n "$devfile" ]; then
    devfile=${devfile##*v2: }
    npx @eclipse-che/che-theia-devworkspace-handler --devfile-url:"${devfile}" --output-file:"${dir}"/devworkspace-che-theia-next.yaml
    npx @eclipse-che/che-theia-devworkspace-handler --devfile-url:"${devfile}" --editor:eclipse/che-theia/latest \
    --output-file:"${dir}"/devworkspace-che-theia-latest.yaml

    # When release is happend, we need to replace tags of images in che-theia editor
    if [ -n "$VERSION" ]; then
      cheTheia="quay.io/eclipse/che-theia"
      cheTheiaEndpointRuntimeBinary="${cheTheia}-endpoint-runtime-binary"
      cheMachineExec="quay.io/eclipse/che-machine-exec"
      sed -i "${dir}/devworkspace-che-theia-latest.yaml" \
          -e "s#${cheTheia}@sha256:\([a-z0-9\_]\([\-\.\_a-z0-9]\)*\)#${cheTheia}:${VERSION}#"
      sed -i "${dir}/devworkspace-che-theia-latest.yaml" \
          -e "s#${cheTheiaEndpointRuntimeBinary}@sha256:\([a-z0-9\_]\([\-\.\_a-z0-9]\)*\)#${cheTheiaEndpointRuntimeBinary}:${VERSION}#"
      sed -i "${dir}/devworkspace-che-theia-latest.yaml" \
          -e "s#${cheMachineExec}@sha256:\([a-z0-9\_]\([\-\.\_a-z0-9]\)*\)#${cheMachineExec}:${VERSION}#"
    fi
  fi
done
