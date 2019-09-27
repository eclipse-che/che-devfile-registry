#!/bin/sh
#
# Copyright (c) 2012-2018 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Build Che devfile registry image. Note that this script will read the version
# in ./VERSION; if it is *-SNAPSHOT, devfiles in the registry will use nightly-tagged
# images with the arbitrary user IDs patch. If ./VERSION contains otherwise,
# the devfiles in the registry will instead use the value in ./VERSION.
#

VERSION=$(head -n 1 VERSION)
case $VERSION in
  *SNAPSHOT)
    echo "Snapshot version (${VERSION}) specified in $(find . -name VERSION): building nightly plugin registry."
    docker build -t "quay.io/eclipse/che-devfile-registry:nightly" -f ./build/dockerfiles/Dockerfile .
    ;;
  *)
    echo "Release version specified in $(find . -name VERSION): Building plugin registry for release ${VERSION}."
    docker build -t "quay.io/eclipse/che-devfile-registry:${VERSION}" -f ./build/dockerfiles/Dockerfile . --build-arg "PATCHED_IMAGES_TAG=${VERSION}"
    ;;
esac
