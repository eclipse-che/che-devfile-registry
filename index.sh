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

function buildIndex() {

    FIRST_LINE=true
    echo "["

    ## loop through meta.yaml files
    for i in $(ls -1 ${devfilesDir}/*/meta.yaml | sort); do
        if [[ "$FIRST_LINE" = true ]]; then
            echo "{"
            FIRST_LINE=false
        else
            echo ",{"
        fi

        for field in "${metaInfoFields[@]}"; do
            # get value of needed field in json format
            # note that it may have differrent formats: arrays, string, etc.
            # String value contains quotes, e.g. "str"
            value=$(cat ${i} | grep "$field": | sed -e "s#${field}: ##")
            # if not an array and not already wrapped in quotes
            if [[ ${value} != "["*"]" ]] && [[ ${value} != "\""*"\"" ]]; then 
                # wrap in quotes
                value="\"${value}\""
            fi
            echo "  \"$field\":$value,"
        done

        parentFolderPath=${i%/*}
        echo "  \"links\": {\"self\":\"/$parentFolderPath/devfile.yaml\" }"
        echo "}"
    done
    echo "]"
}

buildIndex
