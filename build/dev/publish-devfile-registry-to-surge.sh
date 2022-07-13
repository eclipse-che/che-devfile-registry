#!/bin/bash
#
# Copyright (c) 2018-2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
set -e -u

DEFAULT_BUILD_DIR="/projects/build"
BUILD_DIR=${BUILD_DIR:-$DEFAULT_BUILD_DIR}

DEFAULT_SURGE_DIR="/projects/surge"
SURGE_DIR=${SURGE_DIR:-$DEFAULT_SURGE_DIR}

DEFAULT_REPO_DIR="/projects/che-devfile-registry"
REPO_DIR=${REPO_DIR:-$DEFAULT_REPO_DIR}

DEFAULT_IMAGES_SRC="$REPO_DIR/images"
IMAGES_SRC=${IMAGES_SRC:-$DEFAULT_IMAGES_SRC}

rm "$SURGE_DIR" -rf;
mkdir -p "$SURGE_DIR"/images
cd "$SURGE_DIR"
echo '*' > CORS
cp -rf "$BUILD_DIR/devfiles" "$SURGE_DIR/devfiles"
cp -rf "$IMAGES_SRC"/* "$SURGE_DIR/images"

CHE_DEVFILE_REGISTRY_URL="https://$DEVWORKSPACE_NAMESPACE-$DEVWORKSPACE_NAME.surge.sh"
CHE_DEVFILE_REGISTRY_INTERNAL_URL="https://$DEVWORKSPACE_NAMESPACE-$DEVWORKSPACE_NAME.surge.sh"
DEVFILES_DIR=${SURGE_DIR}/devfiles

export CHE_DEVFILE_REGISTRY_URL
export CHE_DEVFILE_REGISTRY_INTERNAL_URL
export DEVFILES_DIR
"$REPO_DIR/build/dockerfiles/entrypoint.sh" echo "done running entrypoint.sh to publish to surge"

while IFS= read -r -d '' directory
do
  (cd "$directory" && tree -H '.' -L 1 --noreport --charset utf-8 | sed '/<p class="VERSION">/,/<\/p>/d' > index.html);
done <   <(find . -type d -print0)

surge ./ "$DEVWORKSPACE_NAMESPACE-$DEVWORKSPACE_NAME.surge.sh" && echo "Checkout the published devfile registry at https://$DEVWORKSPACE_NAMESPACE-$DEVWORKSPACE_NAME.surge.sh/devfiles/"
