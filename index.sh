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

# Arguments:
# 1 - folder to search files in
function buildIndex() {
    metaInfoFields=('displayName' 'description' 'icon')

    ## search for all devfiles
    readarray -d '' arr < <(find "$1" -name '*.yaml' -print0)
    FIRST_LINE=true
    echo "["

    ## now loop through devfiles
    for i in "${arr[@]}"
    do
        if [ "$FIRST_LINE" = true ] ; then
            echo "{"
            FIRST_LINE=false
        else
            echo ",{"
        fi

        for field in "${metaInfoFields[@]}"
        do
            value="$(yq r "$i" "$field" | sed 's/^"\(.*\)"$/\1/')"
            echo "  \"$field\":\"$value\","
            yq delete -i $i $field
        done

        echo "  \"links\": {\"self\":\"/$i\" }"
        echo "}"
    done
    echo "]"
}

buildIndex devfiles
