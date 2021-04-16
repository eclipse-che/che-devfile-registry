#!/bin/bash
#
# Copyright (c) 2018-2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
set -e

DEFAULT_BUILD_DIR="/projects/build"
BUILD_DIR=${BUILD_DIR:-$DEFAULT_BUILD_DIR}

DEFAULT_REPO_DIR="/projects/che-devfile-registry"
REPO_DIR=${REPO_DIR:-$DEFAULT_REPO_DIR}

DEFAULT_BASE_IMAGES_SRC="$REPO_DIR/arbitrary-users-patch/base_images"
BASE_IMAGES_SRC=${BASE_IMAGES_SRC:-$DEFAULT_BASE_IMAGES_SRC}

DEFAULT_DEVFILES_SRC="$REPO_DIR/devfiles"
DEVFILES_SRC=${DEVFILES_SRC:-$DEFAULT_DEVFILES_SRC}

rm "$BUILD_DIR" -rf;

cp -rf "$REPO_DIR"/build/scripts "$BUILD_DIR"
cp -rf "$BASE_IMAGES_SRC" "$BUILD_DIR"
cp -rf "$DEVFILES_SRC" "$BUILD_DIR"/devfiles
cd "$BUILD_DIR"
./check_mandatory_fields.sh devfiles
./index.sh > devfiles/index.json

DEVFILE_URL=$(sed -e 's/^"//' -e 's/"$//' <<<"$(curl "$CHE_API_INTERNAL/workspace/${CHE_WORKSPACE_ID}" -H 'Connection: keep-alive'  -H 'Accept: application/json, text/plain, */*' -H "Authorization: Bearer $CHE_MACHINE_TOKEN" | jq '.runtime.machines | .[].servers |  select(.http) | .http.url')");
echo "$DEVFILE_URL" > "$BUILD_DIR"/ENV_CHE_DEVFILE_REGISTRY_URL;
