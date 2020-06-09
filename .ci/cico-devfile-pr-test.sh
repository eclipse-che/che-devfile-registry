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

#Download and import the "common-qe" functions
export IS_TESTS_FAILED="false"
DOWNLOADER_URL=https://raw.githubusercontent.com/eclipse/che/iokhrime-common-centos/tests/.infra/centos-ci/common-qe/downloader.sh
curl $DOWNLOADER_URL -o downloader.sh
chmod u+x downloader.sh
. ./downloader.sh

setConfigProperty "test.suite" "test-all-devfiles"
setConfigProperty "env.setup.environment.script.path" "cico_functions.sh"
setConfigProperty "env.setup.environment.method.name" "setup_environment"

setup_environment

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

WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. "${WORK_DIR}"/../cico_functions.sh
build_and_push

installChectl

startCheServer "$CHE_SERVER_PATCH"

runTest

getOpenshiftLogs

archiveArtifacts "che-devfile-registry-prcheck"

if [ "$IS_TESTS_FAILED" == "true" ]; then
  exit 1;
fi
