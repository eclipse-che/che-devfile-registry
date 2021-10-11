#!/bin/bash
# Release process automation script. 
# Used to create branch/tag, update VERSION files
# and and trigger release by force pushing changes to the release branch 

# set to 1 to actually trigger changes in the release branch
TRIGGER_RELEASE=0 
NOCOMMIT=0
TMP=""
REPO=git@github.com:eclipse-che/che-devfile-registry
REGISTRY=quay.io
ORGANIZATION=eclipse

SCRIPT_DIR=$(cd "$(dirname "$0")" || exit; pwd)

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '-t'|'--trigger-release') TRIGGER_RELEASE=1; NOCOMMIT=0; shift 0;;
    '-v'|'--version') VERSION="$2"; shift 1;;
    '-tmp'|'--use-tmp-dir') TMP=$(mktemp -d); shift 0;;
    '-n'|'--no-commit') NOCOMMIT=1; TRIGGER_RELEASE=0; shift 0;;
  esac
  shift 1
done

usage ()
{
  echo "Usage: $0  --version [VERSION TO RELEASE] [--trigger-release]"
  echo "Example: $0 --version 7.27.0 --trigger-release"; echo
}

verifyContainerExistsWithTimeout()
{
  local container_to_check=$1
  this_timeout=$2
  containerExists=0
  count=1
  (( timeout_intervals=this_timeout*3 ))
  while [[ $count -le $timeout_intervals ]]; do # echo $count
    echo "       [$count/$timeout_intervals] Verify ${container_to_check} exists..." 
    # check if the container exists
    verifyContainerExists "${container_to_check}"

    # container exists
    if [[ ${containerExists} -eq 1 ]]; then
      exit 0
    fi

    # -1 indicates, that server didn't found the container and replied with message "UNKNOWN MANIFEST"
    if [[ ${containerExists} -eq -1 ]]; then
      echo "[ERROR] UNKNOWN MANIFEST: container ${container_to_check} is not found!"
      exit 1
    fi

    (( count=count+1 ))
    sleep 20s
  done

  # or report an error
  echo "[ERROR] Did not find ${container_to_check} after ${this_timeout} minutes - script must exit!"
  exit 1
}

#
# Checks the container existence
#
# Returns
#   1: found; 0: not found; -1: unknown manifest 
#
verifyContainerExists()
{
  this_containerURL="${1}"
  this_image=""; this_tag=""
  this_image=${this_containerURL#*/}
  this_tag=${this_image##*:}
  this_image=${this_image%%:*}
  this_url="https://quay.io/v2/${this_image}/manifests/${this_tag}"

  # get result=tag if tag found, result="null" if not
  result="$(curl -sSL "${this_url}"  -H "Accept: application/vnd.docker.distribution.manifest.list.v2+json" 2>&1 || true)"

  if [ -n "${result}" ]; then
    error=$(echo "${result}" | jq -r '.errors[0].code')
    if [[ ${error} == "MANIFEST_UNKNOWN" ]]; then
      containerExists=-1
      return
    fi

    if [[ $(echo "$result" | jq -r '.schemaVersion' || true) == "1" ]] && [[ $(echo "$result" | jq -r '.tag' || true) == "$this_tag" ]]; then
      echo "[INFO] Found ${this_containerURL} (tag = $this_tag)"
      containerExists=1
      return
    elif [[ $(echo "$result" | jq -r '.schemaVersion' || true) == "2" ]]; then
      arches=$(echo "$result" | jq -r '.manifests[].platform.architecture')
      if [[ $arches ]]; then
          echo "[INFO] Found ${this_containerURL} (arches = $arches)"
      fi
      containerExists=1
      return
    fi
  fi

  containerExists=0
}

checkRequiredImagesExist()
{
  readarray -d '' devfiles < <(find devfiles -name 'devfile.yaml' -print0)
  for devfile in "${devfiles[@]}"; do
      devfile="${SCRIPT_DIR}/${devfile}"
      if [ -e "${devfile}" ] ; then
        local images
        images=$(grep "image: quay.io/" < "${devfile}")
        if [ -n "${images}" ]; then
          images="${images//image: /}"
          for image in ${images} ; do
            verifyContainerExistsWithTimeout "${image}" 1 &
          done
        fi

      fi
  done

  wait
}

performRelease() 
{
  set -xe

  #Build and push patched base images and happy path image
  TAG=$(head -n 1 VERSION)
  export TAG

  # Build and push happy path image, which depends on the above
  ./happy-path/build_happy_path_image.sh --push --rm
  
  checkRequiredImagesExist

  #Build and push images
  PLATFORMS="$(cat PLATFORMS)"
  IMAGE=che-devfile-registry
  VERSION=$(head -n 1 VERSION)
  SHORT_SHA1=$(git rev-parse --short HEAD)
  DOCKERFILE_PATH=./build/dockerfiles/Dockerfile
  docker buildx build \
    --push \
    --platform "${PLATFORMS}" \
    --tag "${REGISTRY}/${ORGANIZATION}/${IMAGE}:${VERSION}" \
    --tag "${REGISTRY}/${ORGANIZATION}/${IMAGE}:${SHORT_SHA1}" \
    --tag "${REGISTRY}/${ORGANIZATION}/${IMAGE}:latest" \
    -f "${DOCKERFILE_PATH}" \
    --target registry .

  set +xe
}

if [[ ! ${VERSION} ]]; then
  usage
  exit 1
fi

# derive branch from version
BRANCH=${VERSION%.*}.x

# if doing a .0 release, use main; if doing a .z release, use $BRANCH
if [[ ${VERSION} == *".0" ]]; then
  BASEBRANCH="main"
else 
  BASEBRANCH="${BRANCH}"
fi

fetchAndCheckout ()
{
  bBRANCH="$1"
  git fetch origin "${bBRANCH}:${bBRANCH}"; git checkout "${bBRANCH}"
}

# work in tmp dir if --use-tmp-dir (not required when running as GH action)
if [[ $TMP ]] && [[ -d $TMP ]]; then
  pushd "$TMP" > /dev/null || exit 1
  # get sources from ${BASEBRANCH} branch
  echo "Check out ${REPO} to ${TMP}/${REPO##*/}"
  git clone "${REPO}" -q
  cd "${REPO##*/}" || true
fi
fetchAndCheckout "${BASEBRANCH}"

# create new branch off ${BASEBRANCH} (or check out latest commits if branch already exists), then push to origin
if [[ "${BASEBRANCH}" != "${BRANCH}" ]]; then
  git branch "${BRANCH}" || git checkout "${BRANCH}" && git pull origin "${BRANCH}"
  git push origin "${BRANCH}"
  fetchAndCheckout "${BRANCH}"
fi

commitChangeOrCreatePR()
{
  if [[ ${NOCOMMIT} -eq 1 ]]; then
    echo "[INFO] NOCOMMIT = 1; so nothing will be committed. Run this script with no flags for usage + list of flags/options."
  else
    aVERSION="$1"
    aBRANCH="$2"
    PR_BRANCH="$3"

    if [[ ${PR_BRANCH} == *"add"* ]]; then
      COMMIT_MSG="[release] Add ${aVERSION} plugins in ${aBRANCH}"
    else 
      COMMIT_MSG="[release] Bump to ${aVERSION} in ${aBRANCH}"
    fi

    # commit change into branch
    git add -A || true
    git commit -s -m "${COMMIT_MSG}"
    git pull origin "${aBRANCH}"

    PUSH_TRY="$(git push origin "${aBRANCH}")"
    # shellcheck disable=SC2181
    if [[ $? -gt 0 ]] || [[ $PUSH_TRY == *"protected branch hook declined"* ]]; then
      # create pull request for main branch, as branch is restricted
      git branch "${PR_BRANCH}"
      git checkout "${PR_BRANCH}"
      git pull origin "${PR_BRANCH}"
      git push origin "${PR_BRANCH}"
      lastCommitComment="$(git log -1 --pretty=%B)"
      hub pull-request -f -m "${lastCommitComment}" -b "${aBRANCH}" -h "${PR_BRANCH}"
    fi
  fi
}

# unlike in che-plugin-registry, here we just need to update the VERSION file
updateVersionFile () {
  thisVERSION="$1"
  # update VERSION file with VERSION or NEWVERSION
  echo "${thisVERSION}" > VERSION
}

# bump VERSION file to VERSION
updateVersionFile "${VERSION}"

# commit change into branch
commitChangeOrCreatePR "${VERSION}" "${BRANCH}" "pr-${BRANCH}-to-${VERSION}"

if [[ $TRIGGER_RELEASE -eq 1 ]]; then
  # push new branch to release branch to trigger CI build
  fetchAndCheckout "${BRANCH}"
  performRelease

  # tag the release
  git checkout "${BRANCH}"
  git tag "${VERSION}"
  git push origin "${VERSION}"
fi

# now update ${BASEBRANCH} to the new snapshot version
fetchAndCheckout "${BASEBRANCH}"

# change VERSION file + commit change into ${BASEBRANCH} branch
if [[ "${BASEBRANCH}" != "${BRANCH}" ]]; then
  # bump the y digit
  [[ $BRANCH =~ ^([0-9]+)\.([0-9]+)\.x ]] && BASE=${BASH_REMATCH[1]}; NEXT=${BASH_REMATCH[2]}; (( NEXT=NEXT+1 )) # for BRANCH=7.10.x, get BASE=7, NEXT=11
  NEXTVERSION="${BASE}.${NEXT}.0-SNAPSHOT"
else
  # bump the z digit
  [[ $VERSION =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]] && BASE="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"; NEXT="${BASH_REMATCH[3]}"; (( NEXT=NEXT+1 )) # for VERSION=7.7.1, get BASE=7.7, NEXT=2
  NEXTVERSION="${BASE}.${NEXT}-SNAPSHOT"
fi

# bump VERSION file to NEXTVERSION
updateVersionFile "${NEXTVERSION}"
commitChangeOrCreatePR "${NEXTVERSION}" "${BASEBRANCH}" "pr-${BASEBRANCH}-to-${NEXTVERSION}"

# cleanup tmp dir
if [[ $TMP ]] && [[ -d $TMP ]]; then
  popd >/dev/null || true
  rm -fr "$TMP"
fi
