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

BRANCH_NAME="new-base-image-digests"
COMMIT_MSG="[update] Update digests in base_images"
MAIN_BRANCH="main"


# colors
BLUE='\033[1;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BROWN='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'
UNDERLINE='\033[4m'

PULL_REQUEST=false
while [[ "$#" -gt 0 ]]; do
  case $1 in
    '--pr') PULL_REQUEST=true; shift 0;;
  esac
  shift 1
done


echo "> checking sidecar image digects..."

# Compute directory
BASE_DIR=$(cd "$(dirname "$0")"; pwd)
ROOT_DIR=$(cd "${BASE_DIR}/../.."; pwd)

cd "${ROOT_DIR}"

# echo
# echo "===================================================================="
# echo "> ROOT DIR ${ROOT_DIR}"
# ls -la
# echo "===================================================================="
# echo

UPDATED=""

check_image_digest() {
  echo
  local image="$1"

  # Compute Docker image name
  local image_name="${REGISTRY}/${ORGANIZATION}/che-${image}"

  # fetch base image name from the Dockerfile
  local base_image_name=$(cat "${ROOT_DIR}/dockerfiles/${image}/Dockerfile" | grep "ARG BASE_IMAGE=" | cut -d '"' -f 2)

  # fetch base image digest from the Dockerfile
  local base_image_digest=$(cat "${ROOT_DIR}/dockerfiles/${image}/Dockerfile" | grep "FROM " | cut -d ' ' -f 2)

  echo -e "Checking ${GREEN}${image_name}${NC} based on ${BLUE}${base_image_name}${NC} ..."

  # echo "> digest ${base_image_digest}"

  local latest_digest="$(skopeo inspect --tls-verify=false docker://"${base_image_name}" 2>/dev/null | jq -r '.Digest')"
  latest_digest="${base_image_name%:*}@${latest_digest}"

  # echo "> latest_digest [${latest_digest}]"


  if [[ "${latest_digest}" != "${base_image_digest}" ]]; then
    echo -e "\n${RED}Detected newer image digest${NC} for ${BLUE}${base_image_name}${NC}"
    
    # cp "${ROOT_DIR}/dockerfiles/${image}/Dockerfile" "${ROOT_DIR}/dockerfiles/${image}/Dockerfile.copy"
    sed -i "s|FROM ${base_image_digest}$|FROM ${latest_digest}|" "${ROOT_DIR}/dockerfiles/${image}/Dockerfile"

    UPDATED="${UPDATED}    ${image_name}\n"
  else
    echo -e "Image ${BLUE}${base_image_name}${NC} has valid digest"
  fi
}

create_pr() {
  echo
  echo "> create PR"
  echo

  CHANGES=$(git diff --name-only | grep "dockerfiles/")
  echo -e ">changes\n${CHANGES}\n"

  echo "> current dir $(pwd)"

  set +e

  # commit change into branch

  git check -B ${BRANCH_NAME}

  for change in ${CHANGES} ; do
    git add "${change}"
  done

  git commit -sm "${COMMIT_MSG}"
  git push origin "${BRANCH_NAME}"

  lastCommitComment="$(git log -1 --pretty=%B)"
  hub pull-request -f -m "${lastCommitComment}" -b "${MAIN_BRANCH}" -h "${BRANCH_NAME}"
  set -e
}

# for directory in $(ls "${ROOT_DIR}/dockerfiles") ; do
#   if [ -e "${ROOT_DIR}/dockerfiles/${directory}/Dockerfile" ] ; then
#     check_image_digest ${directory}
#   fi
# done
UPDATED="${UPDATED}    quay.io/eclipse/che-antora-2.3"

echo

if [ ! -z "${UPDATED}" ]; then
  echo -e "Updated(s): \n${UPDATED}\n"

  if ${PULL_REQUEST}; then
    create_pr
  fi
fi
