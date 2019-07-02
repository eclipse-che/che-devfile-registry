#!/bin/bash
set -e

DEFAULT_REGISTRY="quay.io"
REGISTRY=${REGISTRY:-${DEFAULT_REGISTRY}}

while read -r line; do
  base_image_name=$(echo $line | cut -f 1 -d ' ')
  base_image=$(echo $line | cut -f 2 -d ' ')
  echo "Building ${REGISTRY}/eclipse-che/che7-${base_image_name} based on $base_image ..."
  docker build -t "${REGISTRY}/eclipse-che/che7-${base_image_name}" --build-arg FROM_IMAGE=$base_image .
done < base_images
