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

npm install -g npm@10.4.0

VERSION="${1%/}"
if [[ -z "$VERSION" || "$VERSION" == *"-next" ]]; then
  VERSION="main"
fi

CHE_DEVWORKSPACE_GENERATOR_VERSION=7.85.0
PLUGIN_REGISTRY_URL=https://eclipse-che.github.io/che-plugin-registry/${VERSION}/v3

for dir in /build/devfiles/*/
do
  devfile_url=$(grep "v2:" "${dir}"meta.yaml) || :
  if [ -n "$devfile_url" ]; then
    devfile_url=${devfile_url##*v2: }
    devfile_url=${devfile_url%/}
    #generate a temporary devworkspace yaml to fetch git repository name and clone url.
    npm_config_yes=true npx @eclipse-che/che-devworkspace-generator@${CHE_DEVWORKSPACE_GENERATOR_VERSION} \
    --devfile-url:"${devfile_url}" \
    --plugin-registry-url:"${PLUGIN_REGISTRY_URL}" \
    --editor-entry:che-incubator/che-code/latest \
    --output-file:"${dir}"temp.yaml
    
    name=$(yq -r '.spec.template.projects[0].name' "${dir}temp.yaml"  | sed -n '2 p')
    project="${name}={{_INTERNAL_URL_}}/resources/v2/${name}.zip"

    npm_config_yes=true npx @eclipse-che/che-devworkspace-generator@${CHE_DEVWORKSPACE_GENERATOR_VERSION} \
    --devfile-url:"${devfile_url}" \
    --editor-entry:che-incubator/che-code/insiders \
    --plugin-registry-url:"${PLUGIN_REGISTRY_URL}" \
    --output-file:"${dir}"/devworkspace-che-code-insiders.yaml \
    --project."${project}"

    npm_config_yes=true npx @eclipse-che/che-devworkspace-generator@${CHE_DEVWORKSPACE_GENERATOR_VERSION} \
    --devfile-url:"${devfile_url}" \
    --editor-entry:che-incubator/che-code/latest \
    --plugin-registry-url:"${PLUGIN_REGISTRY_URL}" \
    --output-file:"${dir}"/devworkspace-che-code-latest.yaml \
    --project."${project}"

    npm_config_yes=true npx @eclipse-che/che-devworkspace-generator@${CHE_DEVWORKSPACE_GENERATOR_VERSION} \
    --devfile-url:"${devfile_url}" \
    --editor-entry:che-incubator/che-idea/next \
    --plugin-registry-url:"${PLUGIN_REGISTRY_URL}" \
    --output-file:"${dir}"/devworkspace-che-idea-next.yaml \
    --project."${project}"
  fi
done
