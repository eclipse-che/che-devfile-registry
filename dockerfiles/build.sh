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

DEFAULT_REGISTRY="quay.io"
DEFAULT_ORGANIZATION="eclipse"
# DEFAULT_TAG="next"
DEFAULT_TAG=$(git rev-parse --short HEAD)

REGISTRY=${REGISTRY:-${DEFAULT_REGISTRY}}
ORGANIZATION=${ORGANIZATION:-${DEFAULT_ORGANIZATION}}
PREFIX="che-"
TAG=${TAG:-${DEFAULT_TAG}}

# build params
IMAGE_TO_BUILD=""
BUILD_ALL=false
PUSH_IMAGES=false
REMOVE_IMAGES=false

# colors
BLUE='\033[1;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BROWN='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'
UNDERLINE='\033[4m'

# Prepare params
while [[ "$#" -gt 0 ]]; do
  case $1 in
    '-i'|'--image') IMAGE_TO_BUILD="$2"; shift 1;;
    '-a'|'--all') BUILD_ALL=true; shift 0;;
    '-p'|'--push') PUSH_IMAGES=true; shift 0;;
    '-r'|'--rm') REMOVE_IMAGES=true; shift 0;;
  esac
  shift 1
done

print_usage() {
  echo "Usage: build.sh [OPTIONS]"
  echo "Dockerfile Build Tool"
  echo "  -i, --image=IMAGE           image to build"
  echo "  -a, --all                   build all images"
  echo "  -p, --push                  push images after build"
  echo "  -r, --rm                    remove built images"
  echo
  echo "Examples:"
  echo "  build.sh -i quarkus         build che-quarkus image"
  echo "  build.sh -a                 build all images"
  echo
}

# Print usage if options are not provided
if [[ ${BUILD_ALL} == "false" ]] && [[ ! ${IMAGE_TO_BUILD} ]]; then
  print_usage
  exit 1
fi

# Compute directory
BASE_DIR=$(cd "$(dirname "$0")"; pwd)

BUILT_IMAGES=""

build_image() {
  local IMAGE="$1"

  # Compute Docker image name
  local IMAGE_NAME="${REGISTRY}/${ORGANIZATION}/${PREFIX}${IMAGE}:${TAG}"

  local DIR=${BASE_DIR}/${IMAGE}

  # Check for directory
  if [ ! -d ${DIR} ]; then
    printf "\n${RED}ERROR:${NC} Directory ${DIR} does not exist\n\n"
    exit 2
  fi

  # Check for the Dockerfile
  if [ ! -e ${DIR}/Dockerfile ]; then
    printf "\n${RED}ERROR:${NC} No Dockerfile in directory ${DIR}\n\n"
    exit 2
  fi

  printf "Building Docker Image ${GREEN}${IMAGE_NAME}${NC} from ${BLUE}${DIR}${NC} directory\n"

  # Replace macros in Dockerfiles
  local content_docker=$(cat ${DIR}/Dockerfile)

  echo "${content_docker}" > ${DIR}/.Dockerfile

  # grab includes
  local to_include=$(sed -n 's/.*\#{INCLUDE:\(.*\)\}/\1/p' ${DIR}/.Dockerfile)
  # echo && echo ${to_include}

  # perform includes (not use sed {r} to be portable)
  echo "$to_include" | while IFS= read -r filename_to_include ; do
    if [ ! -z "$filename_to_include" ]; then
      # trim argument
      local filename_to_include=$(echo $filename_to_include | xargs)
      local line_to_insert=$(grep -n "\#{INCLUDE:${filename_to_include}}" ${DIR}/.Dockerfile | cut -d ":" -f 1 | head -n 1) 
      local head_line=$(($line_to_insert - 1))
      local tail_line=$(($line_to_insert + 1))
      local content_to_include=$(cat "${DIR}/$filename_to_include")

      head -n ${head_line} "${DIR}/.Dockerfile" > ${DIR}/.Dockerfile2
      echo "$content_to_include" >> ${DIR}/.Dockerfile2
      tail -n +${tail_line} "${DIR}/.Dockerfile" >> ${DIR}/.Dockerfile2

      mv ${DIR}/.Dockerfile2 ${DIR}/.Dockerfile
    fi
  done

  # Build .Dockerfile
  cd "${DIR}/.."
  docker build --cache-from ${IMAGE_NAME} -f ${DIR}/.Dockerfile -t ${IMAGE_NAME} .
  rm ${DIR}/.Dockerfile

  if ${PUSH_IMAGES}; then
    echo "Pushing ${IMAGE_NAME} to remote registry"
    docker push "${IMAGE_NAME}" | cat
  fi

  if ${REMOVE_IMAGES}; then # save disk space by deleting the image we just built/published
    echo "Deleting ${IMAGE_NAME} from local registry"
    docker rmi "${IMAGE_NAME}"
  fi
  BUILT_IMAGES="${BUILT_IMAGES}    ${IMAGE_NAME}\n"
}

build_all() {
  for directory in $(ls "${BASE_DIR}") ; do
    if [ -e ${BASE_DIR}/${directory}/Dockerfile ] ; then
      build_image ${directory}
    fi
  done
}

if [[ ${BUILD_ALL} == "true" ]]; then
  build_all

  if [ ! -z "${BUILT_IMAGES}" ]; then
    echo -e "\nBuilt image(s): \n${BUILT_IMAGES}"
  fi
else
  build_image ${IMAGE_TO_BUILD}
fi
