## Major / Minor Release

Below are the steps needed to do a release. But rather than doing them by hand, you can run this script:

https://github.com/eclipse-che/che-devfile-registry/blob/main/make-release.sh

HOWEVER, because the main branch is protected from commits, the above script will not be able to commit an update to the VERSION file. Instead it must produce a PR.

```
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote: error: At least 1 approving review is required by reviewers with write access.
To github.com:eclipse-che/che-devfile-registry
 ! [remote rejected] main -> main (protected branch hook declined)
```

- create a branch for the release e.g. `7.8.x`
- provide a [PR](https://github.com/eclipse-che/che-devfile-registry/pull/171) with bumping the [VERSION](https://github.com/eclipse-che/che-devfile-registry/blob/main/VERSION) file to the `7.8.x` branch
- [![Release Build Status](https://ci.centos.org/buildStatus/icon?subject=release&job=devtools-che-devfile-registry-release/)](https://ci.centos.org/job/devtools-che-devfile-registry-release/) CI is triggered based on the changes in the [`release`](https://github.com/eclipse-che/che-devfile-registry/tree/release) branch (not `7.8.x`).

In order to trigger the CI once the [PR](https://github.com/eclipse-che/che-devfile-registry/pull/171) is merged to the `7.8.x` one needs to:

```
 git fetch origin 7.8.x:7.8.x
 git checkout 7.8.x
 git branch release -f 
 git push origin release -f
```

[CI](https://ci.centos.org/job/devtools-che-devfile-registry-release/) will build an image from the [`release`](https://github.com/eclipse-che/che-devfile-registry/tree/release) branch and push it to [quay.io](https://quay.io/organization/eclipse) e.g [quay.io/eclipse/che-devfile-registry:7.8.0](https://quay.io/repository/eclipse/che-devfile-registry?tab=tags&tag=7.8.0)

The last thing is the tag `7.8.0` creation from the `7.8.x` branch

```
git checkout 7.8.x
git tag 7.8.0
git push origin 7.8.0
```

After the release, the `VERSION` file should be bumped in the main branch, e.g. to `7.75.0-next`.

## Service / Bugfix  Release

The release process is the same as for the Major / Minor one, but the values passed to the `make-release.sh` script will differ so that work is done in the existing 7.7.x branch.

```
./make-release.sh --repo git@github.com:eclipse-che/che-devfile-registry --version 7.7.1 --trigger-release
```

