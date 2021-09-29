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

BRANCH_NAME="update-base-images"
COMMIT_MSG="chore(digests): update dockerfile base images"
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

echo "> ROOT DIR ${ROOT_DIR}"

UPDATED=""

#
# checks digest for image
#
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

  local latest_digest="$(skopeo inspect --tls-verify=false docker://"${base_image_name}" 2>/dev/null | jq -r '.Digest')"
  latest_digest="${base_image_name%:*}@${latest_digest}"

  if [[ "${latest_digest}" != "${base_image_digest}" ]]; then
    echo -e "\n${RED}Detected newer image digest${NC} for ${BLUE}${base_image_name}${NC}"
    
    sed -i "s|FROM ${base_image_digest}$|FROM ${latest_digest}|" "${ROOT_DIR}/dockerfiles/${image}/Dockerfile"

    UPDATED="${UPDATED}    ${image_name}\n"
  else
    echo -e "Image ${BLUE}${base_image_name}${NC} has valid digest"
  fi
}

#
# creates pull request with changes
#
create_pr() {
  local changes=$(git diff --name-only | grep "dockerfiles/")

  # commit change into branch
  for change in ${changes} ; do
    git add "${change}"
  done

  git commit -sm "${COMMIT_MSG}"

  # get last commit sha
  local commit_sha=$(git rev-parse --short HEAD)

  # compute branch name
  local branch="${BRANCH_NAME}-${commit_sha}"
  
  # create and push new branch
  git checkout -B "${branch}"
  git push origin "${branch}"

  # create pull request
  local commit_comment="$(git log -1 --pretty=%B)"
  hub pull-request -f -m "${commit_comment}" -b "${MAIN_BRANCH}" -h "${branch}"
}

#
# scan ./dockerfiles/ directory
#
for directory in $(ls "${ROOT_DIR}/dockerfiles") ; do
  if [ -e "${ROOT_DIR}/dockerfiles/${directory}/Dockerfile" ] ; then
    # update Dockerfiles if parent image uses new digest
    check_image_digest ${directory}
  fi
done

echo

#
# creates Pull Request with changes
#
if [ ! -z "${UPDATED}" ]; then
  echo -e "Updated(s): \n${UPDATED}\n"

  echo
  echo "===================================================================="
  echo "> git status"
  git status
  echo "===================================================================="
  echo

  if ${PULL_REQUEST}; then
    create_pr
  fi
fi