#!/bin/bash
#
# Copyright (c) 2022 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

set -e

CHE_DEVWORKSPACE_GENERATOR_VERSION=0.0.1-c8bd5c0

for dir in /build/devfiles/*/
do
  devfile_url=$(grep "v2:" "${dir}"meta.yaml) || :
  if [ -n "$devfile_url" ]; then
    devfile_url=${devfile_url##*v2: }
    devfile_url=${devfile_url%/}
    devfile_repo=${devfile_url%/tree*}
    name=$(basename "${devfile_repo}")
    project="${name}={{_INTERNAL_URL_}}/resources/v2/${name}.zip"

    npm_config_yes=true npx @eclipse-che/che-devworkspace-generator@${CHE_DEVWORKSPACE_GENERATOR_VERSION} \
    --devfile-url:"${devfile_url}" \
    --editor-entry:che-incubator/che-code/insiders \
    --output-file:"${dir}"/devworkspace-che-code-insiders.yaml \
    --project."${project}"

    npm_config_yes=true npx @eclipse-che/che-devworkspace-generator@${CHE_DEVWORKSPACE_GENERATOR_VERSION} \
    --devfile-url:"${devfile_url}" \
    --editor-entry:eclipse/che-theia/latest \
    --output-file:"${dir}"/devworkspace-che-theia-latest.yaml \
    --project."${project}"

    npm_config_yes=true npx @eclipse-che/che-devworkspace-generator@${CHE_DEVWORKSPACE_GENERATOR_VERSION} \
    --devfile-url:"${devfile_url}" \
    --editor-entry:che-incubator/che-idea/next \
    --output-file:"${dir}"/devworkspace-che-idea-next.yaml \
    --project."${project}"
  fi
done
