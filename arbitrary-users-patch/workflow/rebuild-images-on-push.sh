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

PUSH=""
REMOVE=""

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '--push') PUSH="--push"; shift 0;;
    '--rm') REMOVE="--rm"; shift 0;;
  esac
  shift 1
done

# Compute directory
BASE_DIR=$(cd "$(dirname "$0")"; pwd)
ROOT_DIR=$(cd ${BASE_DIR}/../..; pwd)

cd "${ROOT_DIR}"

echo
echo "===================================================================="
echo "> ROOT DIR ${ROOT_DIR}"
ls -la
echo "===================================================================="
echo

# COMMIT_SHA
DEFAULT_COMMIT_SHA=$(git rev-parse --short HEAD)
# DEFAULT_COMMIT_SHA=$(git log -n1 --format="%h")
COMMIT_SHA=${COMMIT_SHA:-${DEFAULT_COMMIT_SHA}}


echo "> git log ----------------------------------------------------------"
GIT_LOG=$(git log --pretty=oneline -n10)
echo "${GIT_LOG}"
echo "--------------------------------------------------------------------"
echo

echo "> changes in ${COMMIT_SHA} -----------------------------------------------"
CHANGES=$(git show --pretty="format:" --name-only ${COMMIT_SHA})
echo "${CHANGES}"
echo "--------------------------------------------------------------------"
echo


# rebuild all the images if changes in
#     dockerfiles/base.dockerfile
#     dockerfiles/entrypoint.sh
#     dockerfiles/install-editor-tooling.sh
set +e
CHANGES=$(git show --pretty="format:" --name-only ${COMMIT_SHA} | grep -E "dockerfiles/base.dockerfile|dockerfiles/entrypoint.sh|dockerfiles/install-editor-tooling.sh")
set -e

if [ ! -z "${CHANGES}" ]; then
  echo -e "\nRebuild ALL images"
  ./dockerfiles/build.sh --all ${PUSH} ${REMOVE}
  exit 0
fi

# rebuild specific image if something chaned in dockerfiles/
set +e
CHANGES=$(git show --pretty="format:" --name-only ${COMMIT_SHA} | grep "dockerfiles/")
set -e

if [ ! -z "${CHANGES}" ]; then
  echo -e "\nRebuild SPECIFIC images:"

  BUILT_IMAGES=""

  for change in ${CHANGES} ; do
    name=$(echo "${change}" | cut -d"/" -f2)
    ./dockerfiles/build.sh --image ${name} ${PUSH} ${REMOVE}
    BUILT_IMAGES="${BUILT_IMAGES}    ${name}\n"
  done

  if [ ! -z "${BUILT_IMAGES}" ]; then
    echo -e "\nBuilt image(s): \n${BUILT_IMAGES}"
  fi

  exit 0
fi

echo "It is not needed to rebuild base images"
