## Major / Minor Release

Below are the steps needed to do a release. But rather than doing them by hand, you can run this script:

https://github.com/eclipse/che-devfile-registry/blob/master/RELEASE.sh

HOWEVER, because the master branch is protected from commits, the above script will not be able to commit an update to the VERSION file. Instead it must produce a PR.

```
remote: error: GH006: Protected branch update failed for refs/heads/master.
remote: error: At least 1 approving review is required by reviewers with write access.
To github.com:eclipse/che-devfile-registry
 ! [remote rejected] master -> master (protected branch hook declined)
```

l- create a branch for the release e.g. `7.6.x`
- provide a [PR](https://github.com/eclipse/che-devfile-registry/pull/171) with bumping the [VERSION](https://github.com/eclipse/che-devfile-registry/blob/master/VERSION) file to the `7.6.x` branch
- [![Release Build Status](https://ci.centos.org/buildStatus/icon?subject=release&job=devtools-che-devfile-registry-release/)](https://ci.centos.org/job/devtools-che-devfile-registry-release/) CI is triggered based on the changes in the [`release`](https://github.com/eclipse/che-devfile-registry/tree/release) branch (not `7.6.x`).

In order to trigger the CI once the [PR](https://github.com/eclipse/che-devfile-registry/pull/171) is merged to the `7.6.x` one needs to:

```
 git fetch origin 7.6.x:7.6.x
 git checkout 7.6.x
 git branch release -f 
 git push origin release -f
```

CI will build an image from the [`release`](https://github.com/eclipse/che-devfile-registry/tree/release) branch and push it to [quay.io](https://quay.io/organization/eclipse) e.g [quay.io/eclipse/che-devfile-registry:7.6.0](https://quay.io/repository/eclipse/che-devfile-registry?tab=tags&tag=7.6.0)

The last thing is the tag `7.6.0` creation from the `7.6.x` branch

```
git checkout 7.6.x
git tag 7.6.0
git push origin 7.6.0
```

After the release, the `VERSION` file should be bumped in the master e.g. [`7.7.0-SNAPSHOT`](https://github.com/eclipse/che-devfile-registry/pull/172)

## Service / Bugfix  Release

The release process is very similar to the Major / Minor one, just the existing branch should be used for the `VERSION` file bump e.g. `7.3.x` branch for `7.3.3` release - [PR](https://github.com/eclipse/che-devfile-registry/pull/156) example.

