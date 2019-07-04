#!/bin/bash
#
# Copyright (c) 2018-2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

set -e

# Arguments:
# 1 - folder to search files in
if [[ ! $1 ]]; then echo "Error: must specify path to devfiles, eg., $0 /path/to/che-devfile-registry/devfiles"; exit 1; fi
devfilesDir=$1; devfilesDir=${devfilesDir%/} # trim trailing slash if present

metaInfoFields=('displayName' 'description' 'tags' 'icon' 'globalMemoryLimit')

# check that field value, given in the parameter, is not null or empty
function check_field() {
  if [[ $1 == "null" || $1 = "" ]]; then
    return 1;
  fi
  return 0
}

## loop through meta.yaml files
for i in $(ls -1 ${devfilesDir}/*/meta.yaml | sort); do
    echo "Checking devfile '${i}'"
    id=$(cat ${i} | grep displayName: | sed -e "s#displayName: ##" -e 's#"##g')
    full_id=${id}:${i}

    unset NULL_OR_EMPTY_FIELDS
    for field in "${metaInfoFields[@]}"; do
      value=$(cat ${i} | grep "$field": | sed -e "s#${field}: ##" -e 's#"##g')
      if ! check_field "${value}";then
        NULL_OR_EMPTY_FIELDS+="$field "
      fi
    done

    if [[ -n "${NULL_OR_EMPTY_FIELDS}" ]]; then
      echo "!!!   Null or empty mandatory fields in '${full_id}': $NULL_OR_EMPTY_FIELDS"
      INVALID_FIELDS=true
    fi
done

if [[ -n "${INVALID_FIELDS}" ]]; then
  exit 1
fi
