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

BRANCH_NAME="bump-devfiles"
COMMIT_MSG="chore(digests): bump devfiles to new sidecar tags"
MAIN_BRANCH="main"

PULL_REQUEST=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '--pr') PULL_REQUEST=true; shift 0;;
  esac
  shift 1
done

if ! ${PULL_REQUEST}; then
  echo "To create a pull request with changes run './bump-devfiles-to-new-sidecar-tags.sh --pr'"
  exit 1
fi

# Compute directory
BASE_DIR=$(cd "$(dirname "$0")"; pwd)
ROOT_DIR=$(cd "${BASE_DIR}/../.."; pwd)

cd "${ROOT_DIR}"

set +e
CHANGES=$(git status | grep "devfiles/")
set -e

if [ -z "${CHANGES}" ]; then
  echo "All the devfiles are up to date."
  exit 0
fi

# get last commit sha
COMMIT_SHA=$(git rev-parse --short HEAD)

# compute branch name
BRANCH="${BRANCH_NAME}-${COMMIT_SHA}"

# create and push new branch
git checkout -B "${BRANCH}"

# add files to index
CHANGES="${CHANGES//modified:/}"
for CHANGE in ${CHANGES} ; do
  git add "${CHANGE}"
done

git status

# commoit changes
git commit -sm "${COMMIT_MSG}"
git push origin "${BRANCH}"

# create pull request
COMMIT_COMMENT="$(git log -1 --pretty=%B)"
hub pull-request -f -m "${COMMIT_COMMENT}" -b "${MAIN_BRANCH}" -h "${BRANCH}"
