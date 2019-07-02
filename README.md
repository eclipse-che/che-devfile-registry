[![Build Status](https://ci.centos.org/buildStatus/icon?job=devtools-che-devfile-registry-build-master/)](https://ci.centos.org/job/devtools-che-devfile-registry-build-master/)

# Eclipse Che devfile registry

This repository holds ready-to-use Devfiles for different languages and technologies.

## Build Eclipse Che devfile registry docker image

Execute
```shell
docker build --no-cache -t openshiftio/che-devfile-registry .
```
Where `--no-cache` is needed to prevent usage of cached layers with devfile registry files.
Useful when you change devfile files and rebuild the image.

Note that the Dockerfiles feature multi-stage build, so it requires Docker of version 17.05 and higher.
Though you may also just provide the image to the older versions of Docker (ex. on Minishift) by having it build on newer version, and pushing and pulling it from Docker Hub.

`quay.io/openshiftio/che-devfile-registry:latest` image would be rebuilt after each commit in master

## OpenShift
You can deploy Che devfile registry on Openshift with command.
```
  oc new-app -f deploy/openshift/che-devfile-registry.yaml \
             -p IMAGE="quay.io/openshiftio/che-devfile-registry" \
             -p IMAGE_TAG="latest" \
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

## Docker
```
docker run -it --rm -p 8080:8080 quay.io/openshiftio/che-devfile-registry
```

### License
Che is open sourced under the Eclipse Public License 2.0.
