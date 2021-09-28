#!/bin/bash
#
# Copyright (c) 2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# See: https://sipb.mit.edu/doc/safe-shell/

set -e
set -u

REGISTRY="quay.io"
ORGANIZATION="eclipse"

# colors
BLUE='\033[1;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BROWN='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'
UNDERLINE='\033[4m'



echo "> check sidecar image digects..."

# Compute directory
BASE_DIR=$(cd "$(dirname "$0")"; pwd)
ROOT_DIR=$(cd ${BASE_DIR}/../../dockerfiles; pwd)

cd "${ROOT_DIR}"

echo
echo "===================================================================="
echo "> ROOT DIR ${ROOT_DIR}"
ls -la
echo "===================================================================="
echo

UPDATED=""

check_image_digest() {
  echo
  local image="$1"

  # Compute Docker image name
  local image_name="${REGISTRY}/${ORGANIZATION}/che-${image}"

  # fetch base image name from the Dockerfile
  local base_image_name=$(cat "${ROOT_DIR}/${image}/Dockerfile" | grep "ARG BASE_IMAGE=" | cut -d '"' -f 2)

  # fetch base image digest from the Dockerfile
  local base_image_digest=$(cat "${ROOT_DIR}/${image}/Dockerfile" | grep "FROM " | cut -d ' ' -f 2)

  echo -e "Checking ${GREEN}${image_name}${NC} based on ${BLUE}${base_image_name}${NC} ..."

  # echo "> digest ${base_image_digest}"

  local latest_digest="$(skopeo inspect --tls-verify=false docker://"${base_image_name}" 2>/dev/null | jq -r '.Digest')"
  latest_digest="${base_image_name%:*}@${latest_digest}"

  # echo "> latest_digest [${latest_digest}]"


  if [[ "${latest_digest}" != "${base_image_digest}" ]]; then
    echo -e "Detected newer image digest for ${BLUE}${base_image_name}${NC}"
    
    cp "${ROOT_DIR}/${image}/Dockerfile" "${ROOT_DIR}/${image}/Dockerfile.copy"
    sed -i "s|FROM ${base_image_digest}$|FROM ${latest_digest}|" "${ROOT_DIR}/${image}/Dockerfile.copy"

    UPDATED="${UPDATED}    ${image_name}\n"
  else
    echo -e "Image ${BLUE}${base_image_name}${NC} has valid digest"
  fi
}

for directory in $(ls "${ROOT_DIR}") ; do
  if [ -e ${ROOT_DIR}/${directory}/Dockerfile ] ; then
    check_image_digest ${directory}
  fi
done

echo

if [ ! -z "${UPDATED}" ]; then
  echo -e "\nUpdated(s): \n${UPDATED}"
fi
