#!/bin/bash
#
# Copyright (c) 2018-2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Check for new digests for all base images in base_images file
# If found, a pull request will be created with updated digests.
# This script requires GITHUB_TOKEN in order for Hub to be able to create a PR,
# as well as configured Git name & email configuration

set -e

NO_OP="false"
while [[ "$#" -gt 0 ]]; do
  case $1 in
    '-n'|'--no-op') NO_OP="true"; shift 0;;
  esac
  shift 1
done

SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)

REGISTRY="quay.io"
ORGANIZATION="eclipse"
NAME_FORMAT="${REGISTRY}/${ORGANIZATION}"
MAIN_BRANCH="main"

REGISTRY=${REGISTRY:-${DEFAULT_REGISTRY}}
ORGANIZATION=${ORGANIZATION:-${DEFAULT_ORGANIZATION}}

createPR() {
    set +e
    PR_BRANCH="$1"

    COMMIT_MSG="[update] Update digests in base_images"

    # commit change into branch
    git add "${SCRIPT_DIR}"/base_images
    git commit -sm "${COMMIT_MSG}"

    git branch "${PR_BRANCH}"
    git checkout "${PR_BRANCH}"
    git pull origin "${PR_BRANCH}"
    git push origin "${PR_BRANCH}"
    lastCommitComment="$(git log -1 --pretty=%B)"
    hub pull-request -f -m "${lastCommitComment}" -b "${MAIN_BRANCH}" -h "${PR_BRANCH}"
    set -e
}

cp "${SCRIPT_DIR}"/base_images "${SCRIPT_DIR}"/base_images.copy
while read -r line; do
  dev_container_name=$(echo "$line" | tr -s ' ' | cut -f 1 -d ' ')
  base_image_name=$(echo "$line" | tr -s ' ' | cut -f 2 -d ' ')
  base_image_digest=$(echo "$line" | tr -s ' ' | cut -f 3 -d ' ' )
  echo "Checking ${NAME_FORMAT}/${dev_container_name} based on $base_image_name ..."
  latest_digest="$(skopeo inspect --tls-verify=false docker://"${base_image_name}" 2>/dev/null | jq -r '.Digest')"
  echo "latest digest ---> ${latest_digest}"
  latest_digest="${base_image_name%:*}@${latest_digest}"
  if [[ "${latest_digest}" != "${base_image_digest}" ]]; then
    echo "[INFO] Detected newer image digest for ${base_image_name}"
    sed -i "s|${base_image_digest}$|${latest_digest}|" "${SCRIPT_DIR}"/base_images.copy
  else
    echo "[INFO] Image ${base_image_name} has valid digest"
  fi
done < "${SCRIPT_DIR}"/base_images
mv "${SCRIPT_DIR}"/base_images.copy  "${SCRIPT_DIR}"/base_images

set +e
if [[ $(git diff --exit-code "${SCRIPT_DIR}"/base_images) ]]; then
  if [[ ${NO_OP} == "true" ]]; then
    echo "[INFO] Changes detected, see base_images file changes:"
    git diff "${SCRIPT_DIR}"/base_images
  else
    echo "[INFO] Changes detected, generating PR with new digests"
    createPR "new-base-image-digests"
  fi
else
  echo "[INFO] No changes detected for digests, do nothing"
fi
