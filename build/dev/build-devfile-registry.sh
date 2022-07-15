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

DEFAULT_REPO_DIR="/projects/che-devfile-registry"
REPO_DIR=${REPO_DIR:-$DEFAULT_REPO_DIR}

DEFAULT_DEVFILES_SRC="$REPO_DIR/devfiles"
DEVFILES_SRC=${DEVFILES_SRC:-$DEFAULT_DEVFILES_SRC}

rm "$BUILD_DIR" -rf;

cp -rf "$REPO_DIR"/build/scripts "$BUILD_DIR"
cp -rf "$DEVFILES_SRC" "$BUILD_DIR"/devfiles
cd "$BUILD_DIR"
./check_mandatory_fields.sh devfiles
./index.sh > devfiles/index.json
# ./generate_devworkspace_templates.sh

ROUTE_OR_INGRESS="routes"
DEVFILE_HOST=$(kubectl get ${ROUTE_OR_INGRESS} -l "controller.devfile.io/devworkspace_id=${DEVWORKSPACE_ID}" -o json | jq -r '.items[] | select(.metadata.annotations."che.routing.controller.devfile.io/endpoint-name" = "devfile-registry") | .spec.host')
DEVFILE_URL=https://${DEVFILE_HOST}

echo "$DEVFILE_URL" > "$BUILD_DIR"/ENV_CHE_DEVFILE_REGISTRY_URL;
