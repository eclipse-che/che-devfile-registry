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

BASE_DIR=""

ORGANIZATION="eclipse"
PREFIX="che"
TAG="next"

BUILD_IMAGE=""
BUILD_ALL=false

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
    '-i'|'--image') BUILD_IMAGE="$2"; shift 1;;
    '-a'|'--all') BUILD_ALL=true; shift 0;;
  esac
  shift 1
done

print_usage() {
  echo "Usage: build.sh [OPTIONS]"
  echo "Dockerfile Build Tool"
  echo "  -i, --image=IMAGE           image to build"
  echo "  -a, --all                   build all images"
  echo
  echo "Examples:"
  echo "  build.sh -i quarkus         build che-quarkus image"
  echo "  build.sh -a                 build all images"
  echo
}

# Print usage if options are not provided
if [[ ${BUILD_ALL} == "false" ]] && [[ ! ${BUILD_IMAGE} ]]; then
  print_usage
  exit 1
fi

# Compute directory
BASE_DIR=$(cd "$(dirname "$0")"; pwd)

# Compute tag
TAG=$(git rev-parse --short HEAD)


build_image() {
  local IMAGE="$1"

  # Compute Docker image name
  local IMAGE_NAME="${ORGANIZATION}/${PREFIX}-${IMAGE}:${TAG}"

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
else
  build_image ${BUILD_IMAGE}
fi
