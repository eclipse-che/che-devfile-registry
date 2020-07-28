#!/bin/bash
# Copyright (c) 2012-2020 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

set -e

# PR_FILES_CHANGED store all Modified/Created files in Pull Request.
export PR_FILES_CHANGED=$(git --no-pager diff --name-only HEAD $(git merge-base HEAD origin/master))

# filterDevFileYamls function filter yamls from PR into a new array => FILES_CHANGED_ARRAY.
function filterDevFileYamls() {
    export SCRIPT=$(readlink -f "$0")
    export ROOT_DIR=$(dirname $(dirname "$SCRIPT"));

    for files in ${PR_FILES_CHANGED}
    do  
        # Filter only files which are devfiles folder and finish with .yaml extension
        if [[ $files =~ ^devfiles.*.yaml$ ]]; then
            echo "[INFO] Added/Changed new devfile in the current PR: ${files}"
            export FILES_CHANGED_ARRAY+=("${ROOT_DIR}/"$files)
        fi
    done 
}

# checkDevFileImages get the container images from changed devfile.yaml files in PR and check if they have digest.
function checkDevFileImages() {
    export IMAGES=$(yq -r '..|.image?' "${FILES_CHANGED_ARRAY[@]}" | grep -v "null" | uniq)

    for image in ${IMAGES}
    do
        local DIGEST="$(skopeo inspect --tls-verify=false docker://${image} 2>/dev/null | jq -r '.Digest')"
        if [ -z "${DIGEST}" ];
        then
            echo "[ERROR] Image ${image} doesn't contain an valid digest.Digest check script will fail."
            exit 1
        fi
        echo "[INFO] Successfully checked image digest: ${image}"
    done
}

filterDevFileYamls
checkDevFileImages
