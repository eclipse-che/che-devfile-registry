# Eclipse Che devfile registry

This repository holds meta.yaml files that refer to the samples with Devfiles.

Here is an example `meta.yaml` file:

```yaml
---
displayName: Python
description: Python Stack with Python 3.8
tags: ["Community", "Centos", "Python", "pip"]
icon: /images/python.svg
links:
  v2: https://github.com/che-samples/python-hello-world/tree/main
```

Here are all the supported values:
```yaml
---
# the name of the stack
displayName: Python
# the description of the stack
description: Python Stack with Python 3.8
# the list of tags that will be used to search for the devfile
tags: ["Community", "Centos", "Python", "pip"]
# the path to the icon of the stack
icon: /images/python.svg
links:
  # The link to the repository of the project that contains the devfile.yaml with schemaVersion 2.x.y
  v2: https://github.com/che-samples/python-hello-world/tree/main
```

The contents of the devfile registry are published to [GitHub pages](https://eclipse-che.github.io/che-devfile-registry/main/) on every commit. Furthermore, every version is also published to GitHub pages at release time. As an example the `7.31.2` version of the devfile registry was published [here](https://eclipse-che.github.io/che-devfile-registry/7.31.2/).

All published versions of the devfile registry explicitly use plugins from the [che-plugin-registry](https://github.com/eclipse-che/che-plugin-registry) by specifying the `registryUrl` field.

## Build registry container image

This repository contains a `build.sh` script at its root that can be used to build the registry:
```
Usage: ./build.sh [OPTIONS]
Options:
    --help
        Print this message.
    --tag, -t [TAG]
        Docker image tag to be used for image; default: 'next'
    --registry, -r [REGISTRY]
        Docker registry to be used for image; default 'quay.io'
    --organization, -o [ORGANIZATION]
        Docker image organization to be used for image; default: 'eclipse'
    --offline
        Build offline version of registry, with all artifacts included
        cached in the registry; disabled by default.
    --rhel
        Build using the rhel.Dockerfile (UBI images) instead of default
```
By default, the built registry will be tagged `quay.io/eclipse/che-devfile-registry:next`, and will be built with offline mode disabled.

This script listens to the `BUILDER` variable, and will use the tool specified there to build the image. For example:
```sh
BUILDER=buildah ./build.sh
```

will force the build to use `buildah`. If `BUILDER` is not specified, the script will try to use `podman` by default. If `podman` is not installed, then `buildah` will be chosen. If neither `podman` nor `buildah` are installed, the script will finally try to build with `docker`.

Note that the Dockerfiles in this repository utilize multi-stage builds, so Docker version 17.05 or higher is required.

### Offline and airgapped registry images

Using the `--offline` option in `build.sh` will build the registry to contain `zip` files for all projects referenced, which is useful for running Che in clusters that may not have access to GitHub. When building the offline registry, the docker build will

1. Clone all git projects referenced in devfiles, and
2. `git archive` them in the `/resources` path, making them available to workspaces.

When deploying this offline registry, it is necessary to set the environment variable `CHE_DEVFILE_REGISTRY_URL` to the URL of the route/endpoint that exposes the devfile registry, as devfiles need to be rewritten to point to internally hosted zip files.

## Deploy the registry to OpenShift

You can deploy the registry to Openshift as follows:

```bash
  oc new-app -f deploy/openshift/che-devfile-registry.yaml \
             -p IMAGE="quay.io/eclipse/che-devfile-registry" \
             -p IMAGE_TAG="next" \
             -p PULL_POLICY="Always"
```

## Kubernetes

You can deploy Che devfile registry on Kubernetes using [helm](https://docs.helm.sh/). For example if you want to deploy it in the namespace `kube-che` and you are using `minikube` you can use the following command.

```bash
NAMESPACE="kube-che"
DOMAIN="$(minikube ip).nip.io"
helm upgrade --install che-devfile-registry \
    --debug \
    --namespace ${NAMESPACE} \
    --set global.ingressDomain=${DOMAIN} \
    ./deploy/kubernetes/che-devfile-registry/
```

You can use the following command to uninstall it.

```bash
helm delete --purge che-devfile-registry
```

## Run the registry

* Run
```bash
docker run -it --rm --entrypoint httpd-foreground -p 8080:8080 quay.io/eclipse/che-devfile-registry:next
```
* Open http://localhost:8080/devfiles/

# Builds

This repo contains several [actions](https://github.com/eclipse-che/che-devfile-registry/actions), including:
* [![release latest stable](https://github.com/eclipse-che/che-devfile-registry/actions/workflows/release.yml/badge.svg)](https://github.com/eclipse-che/che-devfile-registry/actions/workflows/release.yml)
* [![next builds](https://github.com/eclipse-che/che-devfile-registry/actions/workflows/next-build.yml/badge.svg)](https://github.com/eclipse-che/che-devfile-registry/actions/workflows/next-build.yml)
* [![PR](https://github.com/eclipse-che/che-devfile-registry/actions/workflows/pr-checks.yml/badge.svg)](https://github.com/eclipse-che/che-devfile-registry/actions/workflows/pr-checks.yml)
* [![try in webIDE](https://github.com/eclipse-che/che-devfile-registry/actions/workflows/try-in-web-ide.yaml/badge.svg)](https://github.com/eclipse-che/che-devfile-registry/actions/workflows/try-in-web-ide.yaml)

Want to contribute? Open this project in a Che [![Contribute](https://www.eclipse.org/che/contribute.svg)](https://workspaces.openshift.com#https://github.com/eclipse/che-devfile-registry)

Maintainers can run the latest [![Contribute (nightly)](https://img.shields.io/static/v1?label=nightly%20Che&message=for%20maintainers&logo=eclipseche&color=FDB940&labelColor=525C86)](https://che-dogfooding.apps.che-dev.x6e0.p1.openshiftapps.com/#https://github.com/eclipse-che/che-devfile-registry?df=.devfile-v2.yaml)


Downstream builds can be found at the link below, which is _internal to Red Hat_. Stable builds can be found by replacing the 3.x with a specific version like 3.2.  

* [devfileregistry_3.x](https://main-jenkins-csb-crwqe.apps.ocp-c1.prod.psi.redhat.com/job/DS_CI/job/devfileregistry_3.x/)

NOTE: The registry downstream is a fork of upstream, with different devfile content and support for restricted environments enabled by default.

# License

Che is open sourced under the Eclipse Public License 2.0.
