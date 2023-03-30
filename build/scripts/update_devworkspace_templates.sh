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

# shellcheck disable=SC1091
source ./clone_and_zip.sh

mkdir -p /build/resources/v2/
for dir in /build/devfiles/*/
do
    devfile_url=$(grep "v2:" "${dir}"meta.yaml) || :
        if [ -n "$devfile_url" ]; then
            devfile_url=${devfile_url##*v2: }
            devfile_url=${devfile_url%/}
            devfile_repo=${devfile_url%/tree*}
            name=$(basename "${devfile_repo}")
            clone_and_zip "${devfile_repo}" "${devfile_url##*/}" "/build/resources/v2/$name.zip"
        fi
done
