#!/bin/bash
# Release process automation script. 
# Used to create branch/tag, update VERSION files and and trigger release by force pushing changes to the release branch 

# set to 1 to actually trigger changes in the release branch
TRIGGER_RELEASE=0 

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '-t'|'--trigger-release') TRIGGER_RELEASE=1; shift 0;;
    '-r'|'--repo') REPO="$2"; shift 1;;
    '-v'|'--version') VERSION="$2"; shift 1;;
  esac
  shift 1
done

usage ()
{
  echo "Usage: $0 --repo [GIT REPO TO EDIT] --version [VERSION TO RELEASE] [--trigger-release]"
  echo "Example: $0 --repo git@github.com:eclipse/che-devfile-registry --version 7.7.0 --trigger-release"; echo
}

if [[ ! ${VERSION} ]] || [[ ! ${REPO} ]]; then
  usage
  exit 1
fi

# derive branch from version
BRANCH=${VERSION%.*}.x

# work in tmp dir
TMP=$(mktemp -d); pushd "$TMP" > /dev/null || exit 1

# get sources from master branch
echo "Check out ${REPO} to ${TMP}/${REPO##*/}"
git clone "${REPO}" -q
cd "${REPO##*/}" || exit 1
git fetch origin master:master
git checkout master

# create new branch off master (or check out latest commits if branch already exists), then push to origin
git branch "${BRANCH}" || git checkout "${BRANCH}" && git pull origin "${BRANCH}"
git push origin "${BRANCH}"
git fetch origin "${BRANCH}:${BRANCH}"
git checkout "${BRANCH}"

# change VERSION file + commit change into .x branch
echo "${VERSION}" > VERSION
git commit -s -m "[release] Bump to ${VERSION} in ${BRANCH}" VERSION
git pull origin "${BRANCH}"
git push origin "${BRANCH}"

if [[ $TRIGGER_RELEASE -eq 1 ]]; then
  # push new branch to release branch to trigger CI build
  git fetch origin "${BRANCH}:${BRANCH}"
  git checkout "${BRANCH}"
  git branch release -f 
  git push origin release -f

  # tag the release
  git checkout "${BRANCH}"
  git tag "${VERSION}"
  git push origin "${VERSION}"
fi

# now update master to the new snapshot version
git fetch origin master:master
git checkout master

# change VERSION file + commit change into master branch
[[ $BRANCH =~ ^([0-9]+)\.([0-9]+).x ]] && BASE=${BASH_REMATCH[1]}; NEXT=${BASH_REMATCH[2]}; (( NEXT=NEXT+1 )) # for BRANCH=7.10.x, get BASE=7, NEXT=11
echo "${BASE}.${NEXT}.0-SNAPSHOT" > VERSION
BRANCH=master
COMMIT_MSG="[release] Bump to ${BASE}.${NEXT}.0-SNAPSHOT in ${BRANCH}"
git commit -s -m "${COMMIT_MSG}" VERSION
git pull origin ${BRANCH}

PUSH_TRY="$(git push origin ${BRANCH})"
# shellcheck disable=SC2181
if [[ $? -gt 0 ]] || [[ $PUSH_TRY == *"protected branch hook declined"* ]]; then
PR_BRANCH=pr-master-to-${BASE}.${NEXT}.0-SNAPSHOT
  # create pull request for master branch, as branch is restricted
  git branch "${PR_BRANCH}"
  git checkout "${PR_BRANCH}"
  git pull origin "${PR_BRANCH}"
  git push origin "${PR_BRANCH}"
  lastCommitComment="$(git log -1 --pretty=%B)"
  hub pull-request -o -f -m "${lastCommitComment}

${lastCommitComment}" -b "${BRANCH}" -h "${PR_BRANCH}"
fi 

# cleanup tmp dir
cd /tmp && rm -fr "$TMP"

popd > /dev/null
