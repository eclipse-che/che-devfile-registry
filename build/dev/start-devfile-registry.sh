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

DEFAULT_IMAGES_SRC="$REPO_DIR/images"
IMAGES_SRC=${IMAGES_SRC:-$DEFAULT_IMAGES_SRC}


rm -rf /usr/local/apache2/htdocs/devfiles
rm -rf /usr/local/apache2/htdocs/images/* 

cp -rf "$BUILD_DIR"/devfiles /usr/local/apache2/htdocs/devfiles
cp -rf "$IMAGES_SRC"/* /usr/local/apache2/htdocs/images
CHE_DEVFILE_REGISTRY_URL=$(cat "$BUILD_DIR"/ENV_CHE_DEVFILE_REGISTRY_URL)
CHE_DEVFILE_REGISTRY_INTERNAL_URL="${CHE_DEVFILE_REGISTRY_URL}"
export CHE_DEVFILE_REGISTRY_URL
export CHE_DEVFILE_REGISTRY_INTERNAL_URL
echo "$CHE_DEVFILE_REGISTRY_URL"
/projects/che-devfile-registry/build/dockerfiles/entrypoint.sh echo "Starting Apache ..."
httpd-foreground
