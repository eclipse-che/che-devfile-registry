#!/bin/bash
#
# Copyright (c) 2012-2018 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Arguments
#    $1 - devfiles directory
#    $2 - resources directory, where project zips will be stored.
#
# Only supports downloading projecst from GitHub.

set -e

DEVFILES_DIR="${1}"
RESOURCES_DIR="${2}"
TEMP_DIR="${2}/devfiles_temp/"
TEMP_FILE="${TEMP_DIR}temp.yaml"

# Builds the URL for downloading a GitHub project as a .zip
# Args:
#   $1 - main repo URL; if it ends in '.git', this will be trimmed
#   $2 - branch to download; if empty or 'null', 'master' is used
function build_project_zip_url() {
  location="$1"
  branch="$2"

  # Trim unwanted path portions
  location="${location%/}"
  location="${location%.git}"

  # set branch to "master" if undefined
  if [ -z "$branch" ] || [ "$branch" = "null" ]; then
    branch="master"
  fi

  URL="${location}/archive/${branch}.zip"
  echo "$URL"
}

# Download a project's zip to specified directory. If file already exists, nothing
# is done.
# Args:
#   $1 - URL to download from
#   $2 - path + name of file to save
function download_project_zip() {
  URL="$1"
  destination="$2"
  if [ -f "$destination" ]; then
    echo "    Project already cached"
  else
    echo "    Downloading $URL to $destination"
    wget -O "$destination" -nv "$URL" 2>&1 | sed "s/^/        /g"
  fi
}

# Update devfile to refer to a locally stored zip instead of a public git repo
# Args:
#   $1 - path to devfile to update
#   $2 - name of project to update within devfile
#   $3 - path to downloaded project zip
function update_devfile() {
  devfile="$1"
  project_name="$2"
  destination="$3"
  echo "    Updating devfile $devfile to point at cached project zip $destination"
  # The yq script below will rewrite the project with $project_name to be a zip-type
  # project with provided path. The location field contains a placeholder
  # '{{ DEVFILE_REGISTRY_URL }}' which must be filled at runtime (see 
  # build/dockerfiles/entrypoint.sh script)
  # shellcheck disable=SC2016
  yq -y \
    '(.projects | map(select(.name != $PROJECT_NAME))) as $projects |
    . + {
      "projects": (
        $projects + [{
          "name": $PROJECT_NAME,
          "source": {
            "type": "zip",
            "location": "{{ DEVFILE_REGISTRY_URL }}/\($PROJECT_PATH)"
          }
        }]
      )
    }' "$devfile" \
    --arg "PROJECT_NAME" "${project_name}" \
    --arg "PROJECT_PATH" "${destination}" \
    > "$TEMP_FILE"
  # As a workaround since jq does not support in-place updates, we need to copy
  # to a temp file and then overwrite the original.
  echo "    Copying $TEMP_FILE -> $devfile"
  mv "$TEMP_FILE" "$devfile"

}

readarray -d '' devfiles < <(find "$DEVFILES_DIR" -name 'devfile.yaml' -print0)
mkdir -p "$TEMP_DIR" "$RESOURCES_DIR"
for devfile in "${devfiles[@]}"; do
  echo "Caching project files for devfile $devfile"
  for project in $(yq -c '.projects[]?' "$devfile"); do
    project_name=$(echo "$project" | jq -r '.name')
    echo "    Caching project $project_name"

    type=$(echo "$project" | jq -r '.source.type')
    if [ "$type" != "git" ]; then
      echo "    [WARN]: Project type is not 'git'; skipping."
      continue
    fi

    location=$(echo "$project" | jq -r '.source.location')
    branch=$(echo "$project" | jq -r '.source.branch')
    if ! echo "$location" | grep -q "github"; then
      echo "    [WARN]: Project is not hosted on GitHub; skipping."
      continue
    fi

    URL=$(build_project_zip_url "$location" "$branch")

    filename=$(basename "$URL")
    target=${URL#*//}
    destination="${RESOURCES_DIR%/}/${target}"

    mkdir -p "${destination%${filename}}"
    download_project_zip "$URL" "$destination"

    update_devfile "$devfile" "$project_name" "$destination"
  done
done

rm -rf "$TEMP_DIR"

