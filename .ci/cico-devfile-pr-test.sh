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

function getOpenshiftLogs() {
    echo "====== Che server logs ======"
    oc logs $(oc get pods --selector=component=che -o jsonpath="{.items[].metadata.name}")  || true
    echo "====== Keycloak logs ======"
    oc logs $(oc get pods --selector=component=keycloak -o jsonpath="{.items[].metadata.name}") || true
    echo "====== Che operator logs ======"
    oc logs $(oc get pods --selector=app=che-operator -o jsonpath="{.items[].metadata.name}") || true
}

function archiveArtifacts() {
  JOB_NAME=$1
  DATE=$(date +"%m-%d-%Y-%H-%M")
  echo "Archiving artifacts from ${DATE} for ${JOB_NAME}/${BUILD_NUMBER}"
  cd /root/payload
  ls -la ./artifacts.key
  chmod 600 ./artifacts.key
  chown $(whoami) ./artifacts.key
  mkdir -p ./che/${JOB_NAME}/${BUILD_NUMBER}
  cp -R ./report ./che/${JOB_NAME}/${BUILD_NUMBER}/ || true
  rsync --password-file=./artifacts.key -Hva --partial --relative ./che/${JOB_NAME}/${BUILD_NUMBER} devtools@artifacts.ci.centos.org::devtools/
}

set -x

export IS_TESTS_FAILED="false"
export FAIL_MESSAGE="Build failed."

SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
export SCRIPT_DIR

. "${SCRIPT_DIR}"/che-util.sh
. "${SCRIPT_DIR}"/installation-util.sh

. "${SCRIPT_DIR}"/../cico_functions.sh

load_jenkins_vars
install_deps
setup_environment

# Build & push.

export TAG="PR-${ghprbPullId}"
export IMAGE_NAME="quay.io/eclipse/che-devfile-registry:$TAG"
build_and_push

export FAIL_MESSAGE="Build passed. Image is available on $IMAGE_NAME"

# Install test deps
installOC
installKVM
installAndStartMinishift
installJQ

bash <(curl -sL https://www.eclipse.org/che/chectl/) --channel=next

cat >/tmp/che-cr-patch.yaml <<EOL
spec:
  server:
    devfileRegistryImage: $IMAGE_NAME
    selfSignedCert: true
  auth:
    updateAdminPassword: false
EOL

echo "======= Che cr patch ======="
cat /tmp/che-cr-patch.yaml

# Start Che

if chectl server:start --listr-renderer=verbose -a operator -p openshift --k8spodreadytimeout=360000 --che-operator-cr-patch-yaml=/tmp/che-cr-patch.yaml; then
    echo "Started succesfully"
    oc get checluster -o yaml
else
    echo "======== oc get events ========"
    oc get events
    echo "======== oc get all ========"
    oc get all
    getOpenshiftLogs
    oc get checluster -o yaml || true
    exit 133
fi

#Run tests

createTestWorkspaceAndRunTest

getOpenshiftLogs

archiveArtifacts "che-devfile-registry-prcheck"

if [ "$IS_TESTS_FAILED" == "true" ]; then
  exit 1;
fi
