#!/bin/bash
# Release process automation script. 
# Used to create branch/tag, update VERSION files 
# and trigger release by force pushing changes to the release branch

# set to 1 to actually tag changes in the release branch
TAG_RELEASE=0 
NOCOMMIT=0
TMP=""
REPO=git@github.com:eclipse-che/che-devfile-registry

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '-t'|'--tag-release') TAG_RELEASE=1; NOCOMMIT=0; shift 0;;
    '-v'|'--version') VERSION="$2"; shift 1;;
    '-tmp'|'--use-tmp-dir') TMP=$(mktemp -d); shift 0;;
    '-n'|'--no-commit') NOCOMMIT=1; TAG_RELEASE=0; shift 0;;
  esac
  shift 1
done

usage ()
{
  echo "Usage: $0  --version [VERSION TO RELEASE] [--tag-release]"
  echo "Example: $0 --version 7.27.0 --tag-release"; echo
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
      # create pull request for master branch, as branch is restricted
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

if [[ $TAG_RELEASE -eq 1 ]]; then
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
