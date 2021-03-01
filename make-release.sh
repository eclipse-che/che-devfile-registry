#!/bin/bash
# Release process automation script. 
# Used to create branch/tag, update VERSION files 
# and and trigger release by force pushing changes to the release branch 

# set to 1 to actually trigger changes in the release branch
TRIGGER_RELEASE=0 
NOCOMMIT=0
TMP=""
REPO=git@github.com:eclipse/che-devfile-registry

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

performRelease() 
{
  #Build and push patched base images and happy path image
  TAG=$(head -n 1 VERSION)
  export TAG
  /bin/bash arbitrary-users-patch/happy-path/build_happy_path_image.sh --push
  /bin/bash arbitrary-users-patch/build_images.sh --push

  #Build and push images
  SHORT_SHA1=$(git rev-parse --short HEAD)
  VERSION=$(head -n 1 VERSION)
  IMAGE=che-devfile-registry
  DOCKERFILE_PATH=./build/dockerfiles/Dockerfile
  docker build -t ${IMAGE} -f ${DOCKERFILE_PATH} --build-arg PATCHED_IMAGES_TAG="${VERSION}" --target registry .
  docker tag ${IMAGE} "quay.io/eclipse/${IMAGE}:${SHORT_SHA1}"
  docker push "quay.io/eclipse/${IMAGE}:${SHORT_SHA1}"
  docker tag ${IMAGE} "quay.io/eclipse/${IMAGE}:${VERSION}"
  docker push "quay.io/eclipse/${IMAGE}:${VERSION}"
}

if [[ ! ${VERSION} ]]; then
  usage
  exit 1
fi

# derive branch from version
BRANCH=${VERSION%.*}.x

# if doing a .0 release, use master; if doing a .z release, use $BRANCH
if [[ ${VERSION} == *".0" ]]; then
  BASEBRANCH="master"
else 
  BASEBRANCH="${BRANCH}"
fi

# work in tmp dir
if [[ $TMP ]] && [[ -d $TMP ]]; then
  pushd "$TMP" > /dev/null || exit 1
  # get sources from ${BASEBRANCH} branch
  echo "Check out ${REPO} to ${TMP}/${REPO##*/}"
  git clone "${REPO}" -q
  cd "${REPO##*/}" || exit 1
fi

git fetch origin "${BASEBRANCH}":"${BASEBRANCH}"
git checkout "${BASEBRANCH}"

# create new branch off ${BASEBRANCH} (or check out latest commits if branch already exists), then push to origin
if [[ "${BASEBRANCH}" != "${BRANCH}" ]]; then
  git branch "${BRANCH}" || git checkout "${BRANCH}" && git pull origin "${BRANCH}"
  git push origin "${BRANCH}"
  git fetch origin "${BRANCH}:${BRANCH}"
  git checkout "${BRANCH}"
fi

# change VERSION file
echo "${VERSION}" > VERSION

# commit change into branch
if [[ ${NOCOMMIT} -eq 0 ]]; then
  COMMIT_MSG="[release] Bump to ${VERSION} in ${BRANCH}"
  git commit -s -m "${COMMIT_MSG}" VERSION
  git pull origin "${BRANCH}"
  git push origin "${BRANCH}"
fi

if [[ $TRIGGER_RELEASE -eq 1 ]]; then
  # push new branch to release branch to trigger CI build
  git fetch origin "${BRANCH}:${BRANCH}"
  git checkout "${BRANCH}"
  performRelease

  # tag the release
  git checkout "${BRANCH}"
  git tag "${VERSION}"
  git push origin "${VERSION}"
fi

# now update ${BASEBRANCH} to the new snapshot version
git fetch origin "${BASEBRANCH}":"${BASEBRANCH}"
git checkout "${BASEBRANCH}"

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

# change VERSION file
echo "${NEXTVERSION}" > VERSION
if [[ ${NOCOMMIT} -eq 0 ]]; then
  BRANCH=${BASEBRANCH}
  # commit change into branch
  COMMIT_MSG="[release] Bump to ${NEXTVERSION} in ${BRANCH}"
  git commit -s -m "${COMMIT_MSG}" VERSION
  git pull origin "${BRANCH}"

  PUSH_TRY="$(git push origin "${BRANCH}")"
  # shellcheck disable=SC2181
  if [[ $? -gt 0 ]] || [[ $PUSH_TRY == *"protected branch hook declined"* ]]; then
  PR_BRANCH=pr-master-to-${NEXTVERSION}
    # create pull request for master branch, as branch is restricted
    git branch "${PR_BRANCH}"
    git checkout "${PR_BRANCH}"
    git pull origin "${PR_BRANCH}"
    git push origin "${PR_BRANCH}"
    lastCommitComment="$(git log -1 --pretty=%B)"
    hub pull-request -f -m "${lastCommitComment}" -b "${BRANCH}" -h "${PR_BRANCH}"
  fi 
fi

popd > /dev/null || exit

# cleanup tmp dir
if [[ $TMP ]] && [[ -d $TMP ]]; then
  rm -fr "$TMP"
fi
