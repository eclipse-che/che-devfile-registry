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

FIELDS=('displayName' 'description' 'tags' 'icon' 'globalMemoryLimit')



# check that field value, given in the parameter, is not null or empty
function check_field() {
  if [[ $1 == "null" || $1 = "" ]];then
    return 1;
  fi
  return 0
}

readarray -d '' arr < <(find "$1" -name 'meta.yaml' -print0)

for i in "${arr[@]}"
do
    id=$(yq r "$i" displayName | sed 's/^"\(.*\)"$/\1/')
    full_id=${id}:${i}

    echo "Checking devfile '${i}'"

    unset NULL_OR_EMPTY_FIELDS

    for FIELD in "${FIELDS[@]}"
    do
      VALUE=$(yq r "$i" "$FIELD")

      if ! check_field "${VALUE}";then
        NULL_OR_EMPTY_FIELDS+="$FIELD "
      fi
    done

    if [[ -n "${NULL_OR_EMPTY_FIELDS}" ]];then
      echo "!!!   Null or empty mandatory fields in '${full_id}': $NULL_OR_EMPTY_FIELDS"
      INVALID_FIELDS=true
    fi
done

if [[ -n "${INVALID_FIELDS}" ]];then
  exit 1
fi
