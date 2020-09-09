#!/bin/bash

# ORIGINAL_IMAGE="quay.io/eclipse/che-cpp-rhel7:7.18.1"
imageWithDigest="quay.io/eclipse/che-cpp-rhel7@sha256:02bbffee045b6fdbc40e1824a8a5cfe5f2b25e4dcffa1dad7324c479b1227f59"

SCRIPT=$(readlink -f "$0")
BASE_DIR=$(dirname "${SCRIPT}")

RELATED_IMAGE_PREFIX="RELATED_IMAGE_"
name="che-cpp-rhel7"
tagOrDigest=7.18.1

encodedTag=$(echo "${tagOrDigest}" | base32 -w 0 | tr "=" "_")
imageLabel="devfile-registry-image"

relatedImageEnvName=$(echo "${RELATED_IMAGE_PREFIX}${name}_${imageLabel}_${encodedTag}" | sed -r 's/[-.]/_/g')

eval "export \"${relatedImageEnvName}\"=\"${imageWithDigest}\""
env | grep "RELATED_IMAGE_"

source ${BASE_DIR}/entrypoint.sh
