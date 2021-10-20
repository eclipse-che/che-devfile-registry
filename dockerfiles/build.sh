#!/bin/bash
#
# Copyright (c) 2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# See: https://sipb.mit.edu/doc/safe-shell/

set -e
set -u

DEFAULT_REGISTRY="quay.io"
DEFAULT_ORGANIZATION="eclipse"
DEFAULT_PREFIX="che-"
DEFAULT_TAG=$(git rev-parse --short HEAD)

REGISTRY=${REGISTRY:-${DEFAULT_REGISTRY}}
ORGANIZATION=${ORGANIZATION:-${DEFAULT_ORGANIZATION}}
PREFIX=${PREFIX:-${DEFAULT_PREFIX}}
TAG=${TAG:-${DEFAULT_TAG}}

# build params
IMAGE_TO_BUILD=""
BUILD_ALL=false
PUSH_IMAGES=false
REMOVE_IMAGES=false
UPDATE_DEVFILES=false
UPDATE_HAPPYPATH=false

# colors
BLUE='\033[1;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'


USAGE="
Dockerfile Build Script

Usage: ./build.sh [OPTIONS]
  --image [IMAGE]                   image to build
  --all                             build all images
  --push                            push images after build
  --rm                              remove built images
  --update-devfiles                 bump devfiles to new tags
  --update-happypath                bump happy path dockerfile to new base image tag

Examples:

  build.sh --image quarkus          build che-quarkus image
  build.sh --all                    build all images
"

# Check params
while [[ "$#" -gt 0 ]]; do
  case $1 in
    '--image') IMAGE_TO_BUILD="$2"; shift 1;;
    '--all') BUILD_ALL=true; shift 0;;
    '--push') PUSH_IMAGES=true; shift 0;;
    '--rm') REMOVE_IMAGES=true; shift 0;;
    '--update-devfiles') UPDATE_DEVFILES=true; shift 0;;
    '--update-happypath') UPDATE_HAPPYPATH=true; shift 0;;
  esac
  shift 1
done

# Print usage if options are not provided
if [[ ${BUILD_ALL} == "false" ]] && [[ ! ${IMAGE_TO_BUILD} ]]; then
  echo "${USAGE}"
  exit 1
fi

# Compute directory
DOCKERFILES_DIR=$(cd "$(dirname "$0")"; pwd)
DEVFILES_DIR=$(cd "${DOCKERFILES_DIR}/../devfiles"; pwd)
HAPPYPATH_DIR=$(cd "${DOCKERFILES_DIR}/../happy-path"; pwd)

BUILT_IMAGES=""

update_devfiles() {
  local image="$1"

  # shellcheck disable=SC2045
  for directory in $(ls "${DEVFILES_DIR}") ; do
    local devfile="${DEVFILES_DIR}/${directory}/devfile.yaml";
    if [ -e "${devfile}" ] ; then
      local changes
      set +e
      changes=$(grep "image: ${image}:" < "${devfile}")
      set -e

      if [ -n "${changes}" ]; then
        changes="${changes//image: /}"

        for change in ${changes} ; do
          local replace_from="image: ${change}"
          local replace_to="image: ${image}:${TAG}"
          sed -i "s|${replace_from}$|${replace_to}|" "${devfile}"
        done
      fi

    fi
  done
}

update_happypath() {
  local image="$1"

  local dockerfile="${HAPPYPATH_DIR}/Dockerfile";

  local changes
  set +e
  changes=$(grep "FROM ${image}:" < "${dockerfile}")
  set -e

  if [ -n "${changes}" ]; then
    changes="${changes//FROM /}"

    for change in ${changes} ; do
      local replace_from="FROM ${change}"
      local replace_to="FROM ${image}:${TAG}"
      sed -i "s|${replace_from}$|${replace_to}|" "${dockerfile}"
    done
  fi
}

build_image() {
  local IMAGE="$1"
  
  local DIR="${DOCKERFILES_DIR}/${IMAGE}"

  # Compute Docker image name
  local BASE_NAME="${REGISTRY}/${ORGANIZATION}/${PREFIX}${IMAGE}"
  local IMAGE_NAME="${BASE_NAME}:${TAG}"

  # Check for directory
  if [ ! -d "${DIR}" ]; then
    echo -e "\n${RED}ERROR:${NC} Directory ${DIR} does not exist\n"
    exit 2
  fi

  # Check for the Dockerfile
  if [ ! -e "${DIR}/Dockerfile" ]; then
    echo -e "\n${RED}ERROR:${NC} No Dockerfile in directory ${DIR}\n"
    exit 2
  fi

  echo -e "\nBuilding Docker Image ${GREEN}${IMAGE_NAME}${NC} from ${BLUE}${DIR}${NC} directory"

  # Replace macros in Dockerfiles
  cp -f "${DIR}/Dockerfile" "${DIR}/.Dockerfile"

  # grab includes
  local to_include
  to_include=$(sed -n 's/.*\#{INCLUDE:\(.*\)\}/\1/p' "${DIR}/.Dockerfile")

  # perform includes (not use sed {r} to be portable)
  echo "${to_include}" | while IFS= read -r filename_to_include ; do
    if [ -n "${filename_to_include}" ]; then
      # trim argument
      filename_to_include=$(echo "${filename_to_include}" | xargs)

      local line_to_insert
      line_to_insert=$(grep -n "\#{INCLUDE:${filename_to_include}}" "${DIR}/.Dockerfile" | cut -d ":" -f 1 | head -n 1) 

      local head_line=$((line_to_insert - 1))
      local tail_line=$((line_to_insert + 1))

      local content_to_include
      content_to_include=$(cat "${DIR}/${filename_to_include}")

      head -n ${head_line} "${DIR}/.Dockerfile" > "${DIR}/.Dockerfile2"
      echo "${content_to_include}" >> "${DIR}/.Dockerfile2"
      tail -n +${tail_line} "${DIR}/.Dockerfile" >> "${DIR}/.Dockerfile2"

      mv "${DIR}/.Dockerfile2" "${DIR}/.Dockerfile"
    fi
  done

  # Build .Dockerfile
  cd "${DIR}/.."
  docker build --cache-from "${IMAGE_NAME}" -f "${DIR}/.Dockerfile" -t "${IMAGE_NAME}" .
  rm "${DIR}/.Dockerfile"

  if ${PUSH_IMAGES}; then
    echo "Pushing ${IMAGE_NAME} to remote registry"
    docker push "${IMAGE_NAME}"
  fi

  if ${REMOVE_IMAGES}; then # save disk space by deleting the image we just built/published
    echo "Deleting ${IMAGE_NAME} from local registry"
    docker rmi "${IMAGE_NAME}"
  fi

  if ${UPDATE_DEVFILES}; then
    update_devfiles "${BASE_NAME}"
  fi

  if ${UPDATE_HAPPYPATH}; then
    update_happypath "${BASE_NAME}"
  fi

  BUILT_IMAGES="${BUILT_IMAGES}    ${IMAGE_NAME}\n"
}

build_all() {
  # shellcheck disable=SC2045
  for directory in $(ls "${DOCKERFILES_DIR}") ; do
    if [ -e "${DOCKERFILES_DIR}/${directory}/Dockerfile" ] ; then
      build_image "${directory}"
    fi
  done
}

if [[ ${BUILD_ALL} == "true" ]]; then
  build_all

  if [ -n "${BUILT_IMAGES}" ]; then
    echo -e "\nBuilt image(s): \n${BUILT_IMAGES}"
  fi
else
  build_image "${IMAGE_TO_BUILD}"
fi
