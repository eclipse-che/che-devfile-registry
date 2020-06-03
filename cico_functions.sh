#!/bin/bash
#
# Copyright (c) 2018-2020 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

# Output command before executing
set -x

# Exit on error
set -e

# Source environment variables of the jenkins slave
# that might interest this worker.
function load_jenkins_vars() {
  if [ -e "jenkins-env.json" ]; then
    eval "$(./env-toolkit load -f jenkins-env.json \
            DEVSHIFT_TAG_LEN \
            QUAY_USERNAME \
            QUAY_PASSWORD \
            QUAY_ECLIPSE_CHE_USERNAME \
            QUAY_ECLIPSE_CHE_PASSWORD \
            JENKINS_URL \
            GIT_BRANCH \
            GIT_COMMIT \
            BUILD_NUMBER \
            ghprbSourceBranch \
            ghprbActualCommit \
            BUILD_URL \
            ghprbPullId)"
  fi
}

function check_version() {
  local query=$1
  local target=$2
  echo "$target" "$query" | tr ' ' '\n' | sort -V | head -n1 2> /dev/null
}

function check_buildx_support() {
  docker_version="$(docker --version | cut -d' ' -f3 | tr -cd '0-9.')"
  if [[ $(check_version "$docker_version" "19.03") != 19.03 ]]; then
    echo "CICO: Docker $docker_version greater than or equal to 19.03 is required."
    exit 1
  else
    # Kernel
    kernel_version="$(uname -r)"
    if [[ $(check_version "$kernel_version" "4.8") != "4.8" ]]; then
            echo "Kernel $kernel_version too old - need >= 4.8." \
                " Install a newer kernel."
            exit 1
    else
            echo "kernel $kernel_version has binfmt_misc fix-binary (F) support."
    fi
  fi
}

function install_deps() {
  # We need to disable selinux for now, XXX
  /usr/sbin/setenforce 0  || true

  # Get all the deps in
  yum install -d1 -y yum-utils device-mapper-persistent-data lvm2
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum install -d1 -y docker-ce \
    git

  service docker start
  
  #set buildx env
  export DOCKER_BUILD_KIT=1
  export DOCKER_CLI_EXPERIMENTAL=enabled

  #Enable qemu and binfmt support
  docker run --rm --privileged docker/binfmt:66f9012c56a8316f9244ffd7622d7c21c1f6f28d
  docker run --rm --privileged multiarch/qemu-user-static:4.2.0-7 --reset -p yes

  echo 'CICO: Dependencies installed'
}

function set_release_tag() {
  # Let's obtain the tag based on the
  # version defined in the 'VERSION' file
  TAG=$(head -n 1 VERSION)
  export TAG
}

function set_nightly_tag() {
  # Let's set the tag as nightly
  export TAG="nightly"
}

# Set appropriate environment variables and login to the docker registry
# as the required user.
function setup_environment() {
  export TARGET=${TARGET:-"centos"}
  export REGISTRY="quay.io"

  GIT_COMMIT_TAG=$(echo "$GIT_COMMIT" | cut -c1-"${DEVSHIFT_TAG_LEN}")
  export GIT_COMMIT_TAG

  if [ "$TARGET" == "rhel" ]; then
    export DOCKERFILE_PATH="./build/dockerfiles/rhel.Dockerfile"
    export ORGANIZATION="openshiftio"
    export IMAGE="rhel-che-devfile-registry"
  else
    export DOCKERFILE_PATH="./build/dockerfiles/Dockerfile"
    export ORGANIZATION="eclipse"
    export IMAGE="che-devfile-registry"
    # For pushing to quay.io 'eclipse' organization we need to use different credentials
    export QUAY_USERNAME=${QUAY_ECLIPSE_CHE_USERNAME}
    export QUAY_PASSWORD=${QUAY_ECLIPSE_CHE_PASSWORD}
  fi

  if [ -n "${QUAY_USERNAME}" ] && [ -n "${QUAY_PASSWORD}" ]; then
    docker login -u "${QUAY_USERNAME}" -p "${QUAY_PASSWORD}" "${REGISTRY}"
  else
    echo "Could not login, missing credentials for pushing to the '${ORGANIZATION}' organization"
  fi
}

# Build, tag, and push devfile registry, tagged with ${TAG} and ${GIT_COMMIT_TAG}
function build_and_push() {
  # Let's build and push image to 'quay.io' using git commit hash as tag first
  # Create a new builder instance using buildx
  docker buildx create --use --name builder
  docker buildx inspect --bootstrap

  docker buildx build --platform linux/amd64,linux/s390x -t ${REGISTRY}/${ORGANIZATION}/${IMAGE}:"${GIT_COMMIT_TAG}" -f ${DOCKERFILE_PATH} --target registry --push --progress plain --no-cache .
  echo "CICO: '${GIT_COMMIT_TAG}' version of images pushed to '${REGISTRY}/${ORGANIZATION}' organization"

  # If additional tag is set (e.g. "nightly"), let's build the image accordingly and also push to 'quay.io'
  if [ -n "${TAG}" ]; then
    docker buildx build --platform linux/amd64,linux/s390x -t ${REGISTRY}/${ORGANIZATION}/${IMAGE}:${TAG} -f ${DOCKERFILE_PATH} --target registry --push --progress plain --no-cache .
    echo "CICO: '${TAG}'  version of images pushed to '${REGISTRY}/${ORGANIZATION}' organization"
  fi
}

# Build release version of devfile registry, using ${TAG} / ${GIT_COMMIT_TAG} as a tag. For release
# versions, the devfiles are rewritten to refer to ${TAG}-tagged images with the
# arbitrary user patch
function build_and_push_release() {
  # Create a new builder instance using buildx
  docker buildx create --use --name builder
  docker buildx inspect --bootstrap

  echo "CICO: building release '${TAG}' / '${GIT_COMMIT_TAG}' version of devfile registry"
  docker buildx build --platform=linux/amd64,linux/s390x --build-arg PATCHED_IMAGES_TAG=${TAG} -t ${REGISTRY}/${ORGANIZATION}/${IMAGE}:"${GIT_COMMIT_TAG}" -f ${DOCKERFILE_PATH} --target registry . --push --progress plain --no-cache
  echo "CICO: '${GIT_COMMIT_TAG}' version of devfile registry built and pushed to '${REGISTRY}/${ORGANIZATION}' organization"

  docker buildx build --platform=linux/amd64,linux/s390x --build-arg PATCHED_IMAGES_TAG=${TAG} -t ${REGISTRY}/${ORGANIZATION}/${IMAGE}:${TAG} -f ${DOCKERFILE_PATH} --target registry . --push --progress plain --no-cache
  echo "CICO: release '${TAG}' version of devfile registry built and pushed to '${REGISTRY}/${ORGANIZATION}' organization"
}

# Build images patched to work on OpenShift (work with arbitrary user IDs) and push
# them to registry. NOTE: 'arbitrary-users-patch' images will be pushed only to the public 
# 'https://quay.io/organization/eclipse' organization
function build_patched_base_images() {
  if [ "$TARGET" == "centos" ]; then
    local TAG=${TAG:-${GIT_COMMIT_TAG}}
    echo "CICO: building arbitrary-user-id patched base images with tag '${TAG}'"
    "${SCRIPT_DIR}"/arbitrary-users-patch/build_images.sh --push
    echo "CICO: pushed '${TAG}' version of the arbitrary-user patched base images"
  fi
}

function build_happy_path_image() {
  if [ "$TARGET" == "centos" ]; then
    local TAG=${TAG:-${GIT_COMMIT_TAG}}
    echo "CICO: building image for happy path testing with tag '${TAG}'"
    "${SCRIPT_DIR}"/arbitrary-users-patch/happy-path/build_happy_path_image.sh --push
    echo "CICO: pushed '${TAG}' version of the happy path image"
  fi
}
