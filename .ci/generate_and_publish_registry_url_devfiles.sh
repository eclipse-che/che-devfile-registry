#!/bin/bash
#
# Copyright (c) 2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0


set -e

: "${VERSION:?Variable not set or empty}"
: "${GITHUB_ACTOR:?Variable not set or empty}"
: "${GITHUB_TOKEN:?Variable not set or empty}"

# Use BUILDER if it's set, otherwise auto-detect
if [[ -z ${BUILDER} ]]; then
    echo "BUILDER not specified, trying with podman"
    BUILDER=$(command -v podman || true)
    if [[ ! -x ${BUILDER} ]]; then
        echo "[WARNING] podman is not installed, trying with docker"
        BUILDER=$(command -v docker || true)
        if [[ ! -x ${BUILDER} ]]; then
            echo "[ERROR] neither docker nor podman are installed. Aborting"; exit 1
        fi
    fi
fi

# Get up to date source code using release tag
mkdir /tmp/devfile-registry-gh-pages-publish/
cd /tmp/devfile-registry-gh-pages-publish/
git clone "https://github.com/eclipse-che/che-devfile-registry.git" che-devfile-registry
cd ./che-devfile-registry && git checkout "${VERSION}"

PLUGIN_REGISTRY_URL="https://eclipse-che.github.io/che-plugin-registry/${VERSION}/v3/"

# shellcheck disable=SC2207
DEVFILES=($(find ./devfiles -type f -name "devfile.yaml"))
for devfile in "${DEVFILES[@]}"
do
    LENGTH=$(yq eval '.components | length' "${devfile}")
    LAST_INDEX=$((LENGTH-1))
    for i in $(seq 0 ${LAST_INDEX})
    do
        chePlugin=$(yq eval '.components['"${i}"'].type' "${devfile}")
        hasRegistryUrl=$(yq eval '.components['"${i}"'].registryUrl' "${devfile}")
        if [ "${chePlugin}" == "chePlugin" ] && [ "${hasRegistryUrl}" == "null" ]; then
            yq eval -P '.components['"${i}"'] = .components['"${i}"'] * {"registryUrl":"'"${PLUGIN_REGISTRY_URL}"'"}' -i "${devfile}"
        fi
    done
done

git config --global user.email "che-bot@eclipse.org"
git config --global user.name "CHE Bot"

# Make temporary directory and copy out devfiles and images
mkdir -p /tmp/content/"${VERSION}"
./build.sh --tag gh-pages-generated
${BUILDER} rm -f devfileRegistry
${BUILDER} create --name devfileRegistry quay.io/eclipse/che-devfile-registry:gh-pages-generated
${BUILDER} cp devfileRegistry:/var/www/html/devfiles/ /tmp/content/"${VERSION}"
${BUILDER} cp devfileRegistry:/var/www/html/images/ /tmp/content/"${VERSION}"
${BUILDER} cp devfileRegistry:/var/www/html/README.md /tmp/content/"${VERSION}"

# Run entrypoint
CHE_DEVFILE_REGISTRY_URL="https://eclipse-che.github.io/che-devfile-registry/${VERSION}"
DEVFILES_DIR=/tmp/content/"${VERSION}"/devfiles
export CHE_DEVFILE_REGISTRY_URL
export DEVFILES_DIR
./build/dockerfiles/entrypoint.sh

# Clone GitHub pages
rm -rf ./gh-pages && mkdir gh-pages
cd ./gh-pages
rm -rf ./che-devfile-registry
git clone -b gh-pages "https://github.com/eclipse-che/che-devfile-registry.git" che-devfile-registry
cd ./che-devfile-registry
[ -d "${VERSION}" ] && git rm -r "${VERSION}"

# Copy generated devfiles and commit + push
cp -rf /tmp/content/"${VERSION}" ./
git add ./"${VERSION}"
git commit -m "Publish devfile registry $VERSION - $(date)" -s
git push "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/eclipse-che/che-devfile-registry.git" gh-pages
