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

# Checks for changes in the latest commit
#
# Rebuilds all the images if following files were changed
#     dockerfiles/base.dockerfile
#     dockerfiles/entrypoint.sh
#     dockerfiles/install-editor-tooling.sh
#
# Fetch changed files in `./dockerfiles/` directory, rebuilds necessary images

set -e
set -u

# Compute directory
BASE_DIR=$(cd "$(dirname "$0")"; pwd)
ROOT_DIR=$(cd ${BASE_DIR}/../..; pwd)

cd "${ROOT_DIR}"

SHORT_SHA1=$(git rev-parse --short HEAD)
echo "COMMIT SHA: ${SHORT_SHA1}"
echo "> changes in -------------------------------------------------------"
CHANGES=$(git show --pretty="format:" --name-only ${SHORT_SHA1})
echo "${CHANGES}"
echo "--------------------------------------------------------------------"

# rebuild all the images if changes in
#     dockerfiles/base.dockerfile
#     dockerfiles/entrypoint.sh
#     dockerfiles/install-editor-tooling.sh
set +e
CHANGES=$(git show --pretty="format:" --name-only ${SHORT_SHA1} | grep -E "dockerfiles/base.dockerfile|dockerfiles/entrypoint.sh|dockerfiles/install-editor-tooling.sh")
set -e

if [ ! -z "${CHANGES}" ]; then
  echo -e "\nRebuild ALL images"
  # ./dockerfiles/build.sh -a
  exit 0
fi

# rebuild specific image
set +e
CHANGES=$(git show --pretty="format:" --name-only ${SHORT_SHA1} | grep "dockerfiles/")
set -e

if [ ! -z "${CHANGES}" ]; then
  echo -e "\nRebuild SPECIFIC images:"
  for change in ${CHANGES} ; do
    name=$(echo "${change}" | cut -d"/" -f2)
    echo "    > ${name}"
    # ./dockerfiles/build.sh -i ${name}
  done
fi
