#!/bin/bash
#
# Copyright (c) 2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

set -e

VERSION="${1%/}"
echo "Updating devworkspace templates for version ${VERSION}"
# shellcheck disable=SC1091
source ./clone_and_zip.sh

mkdir -p /build/resources/v2/
for dir in /build/devfiles/*/
do
    clone_url=$(yq -r '.spec.template.projects[0].git.remotes.origin' "${dir}temp.yaml"  | sed -n '2 p')
    revision=$(yq -r '.spec.template.projects[0].git.checkoutFrom.revision' "${dir}temp.yaml"  | sed -n '2 p')
    name=$(yq -r '.spec.template.projects[0].name' "${dir}temp.yaml"  | sed -n '2 p')
    clone_and_zip "${clone_url}" "${revision}" "/build/resources/v2/$name.zip"
    rm "${dir}temp.yaml"
done
