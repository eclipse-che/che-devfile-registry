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

#!/bin/bash
#
# Copyright (c) 2012-2018 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

set -e

REGISTRY="quay.io"
ORGANIZATION="eclipse"
TAG="nightly"
TARGET="registry"
DOCKERFILE="./build/dockerfiles/Dockerfile"

USAGE="
Usage: ./build.sh [OPTIONS]
Options:
    --help
        Print this message.
    --tag, -t [TAG]
        Docker image tag to be used for image; default: 'nightly'
    --registry, -r [REGISTRY]
        Docker registry to be used for image; default 'quay.io'
    --organization, -o [ORGANIZATION]
        Docker image organization to be used for image; default: 'eclipse'
    --offline
        Build offline version of registry, with all sample projects
        cached in the registry; disabled by default.
    --rhel
        Build registry using UBI images instead of default
"

function print_usage() {
    echo -e "$USAGE"
}

function parse_arguments() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -t|--tag)
            TAG="$2"
            shift; shift;
            ;;
            -r|--registry)
            REGISTRY="$2"
            shift; shift;
            ;;
            -o|--organization)
            ORGANIZATION="$2"
            shift; shift;
            ;;
            --offline)
            TARGET="offline-registry"
            shift
            ;;
            --rhel)
            DOCKERFILE="./build/dockerfiles/rhel.Dockerfile"
            shift
            ;;
            *)
            print_usage
            exit 0
        esac
    done
}

parse_arguments "$@"

IMAGE="${REGISTRY}/${ORGANIZATION}/che-plugin-registry:${TAG}"
echo -n "Building image '$IMAGE' "
if [ "$OFFLINE" = true ]; then
    echo "in offline mode"
    docker build \
        -t "$IMAGE" \
        -f ./build/dockerfiles/Dockerfile \
        --build-arg LATEST_ONLY="${LATEST_ONLY}" \
        --target offline-registry .
else
    echo ""
    docker build \
        -t "$IMAGE" \
        -f ./build/dockerfiles/Dockerfile \
        --build-arg LATEST_ONLY="${LATEST_ONLY}" \
        --target registry .
fi

IMAGE="${REGISTRY}/${ORGANIZATION}/che-devfile-registry:${TAG}"

VERSION=$(head -n 1 VERSION)
case $VERSION in
  *SNAPSHOT)
    echo "Snapshot version (${VERSION}) specified in $(find . -name VERSION): building nightly plugin registry."
    docker build -t "${IMAGE}" -f ${DOCKERFILE} --target ${TARGET} .
    ;;
  *)
    echo "Release version specified in $(find . -name VERSION): Building plugin registry for release ${VERSION}."
    docker build -t "${IMAGE}" -f ${DOCKERFILE} --target ${TARGET} --build-arg "PATCHED_IMAGES_TAG=${VERSION}" .
    ;;
esac
