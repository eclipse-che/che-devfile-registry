#!/bin/bash
# shellcheck disable=SC2046,SC2164,SC2086,SC1090,SC2154

# Copyright (c) 2012-2020 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

set -x
set -e

export IS_TESTS_FAILED="false"
export TAG="PR-${ghprbPullId}"
export IMAGE_NAME="quay.io/eclipse/che-devfile-registry:$TAG"
CHE_SERVER_PATCH="$(cat <<EOL
spec:
  server:
    devfileRegistryImage: $IMAGE_NAME
    selfSignedCert: true
  auth:
    updateAdminPassword: false
EOL
)"

#Download and import the "common-qe" functions
DOWNLOADER_URL=https://raw.githubusercontent.com/eclipse/che/iokhrime-common-centos/.ci/common-qe/downloader.sh
curl $DOWNLOADER_URL -o downloader.sh
chmod u+x downloader.sh
. ./downloader.sh

setup_environment

buildAndPushRepoDockerImage "$TAG"

installChectl

startCheServer "$CHE_SERVER_PATCH"

runTest

getOpenshiftLogs

archiveArtifacts "che-devfile-registry-prcheck"

if [ "$IS_TESTS_FAILED" == "true" ]; then
  exit 1;
fi
