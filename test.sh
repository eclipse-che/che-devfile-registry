#!/bin/bash
#
# Copyright (c) 2018-2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Arguments
#    $1 - the new devfile registry image
#

set -e -u

IMG_REG_FILE="./IMG_REG"
IMG_ORG_FILE="./IMG_ORG"
IMG_TAG_FILE="./IMG_TAG"

DEFAULT_REG="image-registry.openshift-image-registry.svc:5000"
DEFAULT_ORG=$(kubectl get namespaces -o json | jq -r '.items[0].metadata.name')
DEFAULT_TAG="custom"

if [ ! -f "${IMG_REG_FILE}" ]; then
    echo "${DEFAULT_REG}" > "${IMG_REG_FILE}"
fi
REG=$(cat "${IMG_REG_FILE}")

if [ ! -f "{$IMG_ORG_FILE}" ]; then
    echo "${DEFAULT_ORG}" > "${IMG_ORG_FILE}"
fi
ORG=$(cat "${IMG_ORG_FILE}")

if [ ! -f "${IMG_TAG_FILE}" ]; then
    echo "${DEFAULT_TAG}" > "${IMG_TAG_FILE}"
fi
TAG=$(cat "${IMG_TAG_FILE}")

# 1. build
BUILDER=podman ./build.sh --tag "${TAG}" --registry "${REG}" --organization "${ORG}"

# 2. push
USER=$(oc whoami | sed 's/://g')
PASSWORD=$(oc whoami -t)
CERT_DIR="/var/run/secrets/kubernetes.io/serviceaccount/"
podman login -u "${USER}" -p "${PASSWORD}" --cert-dir "${CERT_DIR}" "${REG}"
podman push --cert-dir "${CERT_DIR}" "${REG}"/"${ORG}"/che-devfile-registry:"${TAG}"

# 3. run openshift
oc new-app -f deploy/openshift/che-devfile-registry.yaml \
            -p IMAGE="${REG}/${ORG}/che-devfile-registry" \
            -p IMAGE_TAG="${TAG}" \
            -p PULL_POLICY="Always"

# 3. delete openshift
# oc delete deploymentconfigs/che-devfile-registry \
#             services/che-devfile-registry \
#             routes/che-devfile-registry \
#             configmaps/che-devfile-registry

# 4. replace
