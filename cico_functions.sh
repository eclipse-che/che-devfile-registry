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

function install_deps() {
  # We need to disable selinux for now, XXX
  /usr/sbin/setenforce 0  || true

  # Get all the deps in
  yum install -d1 -y yum-utils device-mapper-persistent-data lvm2
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum install -d1 -y docker-ce \
    git

  service docker start
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

function tag_push() {
  local TARGET=$1
  docker tag "${IMAGE}" "$TARGET"
  docker push "$TARGET" | cat
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
  docker build -t ${IMAGE} -f ${DOCKERFILE_PATH} --target registry . | cat
  tag_push "${REGISTRY}/${ORGANIZATION}/${IMAGE}:${GIT_COMMIT_TAG}"
  echo "CICO: '${GIT_COMMIT_TAG}' version of images pushed to '${REGISTRY}/${ORGANIZATION}' organization"

  # If additional tag is set (e.g. "nightly"), let's tag the image accordingly and also push to 'quay.io'
  if [ -n "${TAG}" ]; then
    tag_push "${REGISTRY}/${ORGANIZATION}/${IMAGE}:${TAG}"
    echo "CICO: '${TAG}'  version of images pushed to '${REGISTRY}/${ORGANIZATION}' organization"
  fi
}

# Build release version of devfile registry, using ${TAG} / ${GIT_COMMIT_TAG} as a tag. For release
# versions, the devfiles are rewritten to refer to ${TAG}-tagged images with the
# arbitrary user patch
function build_and_push_release() {
  echo "CICO: building release '${TAG}' / '${GIT_COMMIT_TAG}' version of devfile registry"
  docker build -t ${IMAGE} -f ${DOCKERFILE_PATH} . \
    --build-arg PATCHED_IMAGES_TAG=${TAG} \
    --target registry | cat

  echo "CICO: '${GIT_COMMIT_TAG}' version of devfile registry built"
  tag_push "${REGISTRY}/${ORGANIZATION}/${IMAGE}:${GIT_COMMIT_TAG}"
  echo "CICO: '${GIT_COMMIT_TAG}' version of devfile registry pushed to '${REGISTRY}/${ORGANIZATION}' organization"

  echo "CICO: release '${TAG}' version of devfile registry built"
  tag_push "${REGISTRY}/${ORGANIZATION}/${IMAGE}:${TAG}"
  echo "CICO: release '${TAG}' version of devfile registry pushed to '${REGISTRY}/${ORGANIZATION}' organization"
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
