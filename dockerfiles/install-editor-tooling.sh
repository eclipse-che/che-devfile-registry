#!/bin/sh
#
# Copyright (c) 2020-2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

set -e

TOOLING="vim nano"

# to avoid shellcheck complaints, but also not break if using "${TOOLING}" because of
# ERROR: 'vim nano' is not a valid world dependency, format is name(@tag)([<>~=]version)
# shellcheck disable=SC2086
if command -v dnf 2> /dev/null; then
  dnf install -y ${TOOLING}
  dnf -y clean all
elif command -v yum 2> /dev/null; then
  yum install -y ${TOOLING}
  yum -y clean all
elif command -v apt-get 2> /dev/null; then
  apt-get update
  apt-get install -y ${TOOLING}
  apt-get clean
  rm -rf /var/lib/apt/lists/*
elif command -v apk 2> /dev/null; then
  apk add --no-cache ${TOOLING}
fi
