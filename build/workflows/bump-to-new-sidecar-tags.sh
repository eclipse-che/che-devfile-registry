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

BRANCH_NAME="bump-to-new-sidecar-tags"
COMMIT_MSG="chore(sidecars): bump to new sidecar tags"
MAIN_BRANCH="main"

PULL_REQUEST=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '--pr') PULL_REQUEST=true; shift 0;;
  esac
  shift 1
done

if ! ${PULL_REQUEST}; then
  echo "To create a pull request with changes run './bump-to-new-sidecar-tags.sh --pr'"
  exit 1
fi

echo "> bump to new sidecar tags :: git status ---------------------------"
git status
echo "--------------------------------------------------------------------"
echo

# Compute directory
BASE_DIR=$(cd "$(dirname "$0")"; pwd)
ROOT_DIR=$(cd "${BASE_DIR}/../.."; pwd)

cd "${ROOT_DIR}"

set +e
CHANGES=$(git status | grep -E "devfiles/|happy-path/Dockerfile")
set -e

if [ -z "${CHANGES}" ]; then
  echo "Everything is up to date."
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

# commit changes
git commit -sm "${COMMIT_MSG}"

echo "> pushing updates to ${BRANCH}"
git push origin "${BRANCH}"

# create pull request
echo "> creating a pull request"

COMMIT_COMMENT="$(git log -1 --pretty=%B)"
hub pull-request -f -m "${COMMIT_COMMENT}" -b "${MAIN_BRANCH}" -h "${BRANCH}"
