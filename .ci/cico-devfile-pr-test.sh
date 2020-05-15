#!/bin/bash

function installOC() {
  OC_DIR_NAME=openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit
  curl -vL "https://github.com/openshift/origin/releases/download/v3.11.0/${OC_DIR_NAME}.tar.gz" --output ${OC_DIR_NAME}.tar.gz
  tar -xvf ${OC_DIR_NAME}.tar.gz
  cp ${OC_DIR_NAME}/oc /usr/local/bin
  cp ${OC_DIR_NAME}/oc /tmp
}

function getOpenshiftLogs() {
    echo "====== Che server logs ======"
    oc logs $(oc get pods --selector=component=che -o jsonpath="{.items[].metadata.name}")  || true
    echo "====== Keycloak logs ======"
    oc logs $(oc get pods --selector=component=keycloak -o jsonpath="{.items[].metadata.name}") || true
    echo "====== Che operator logs ======"
    oc logs $(oc get pods --selector=app=che-operator -o jsonpath="{.items[].metadata.name}") || true
}

function installKVM() {
  echo "======== Start to install KVM virtual machine ========"

  yum install -y qemu-kvm libvirt libvirt-python libguestfs-tools virt-install

  curl -L https://github.com/dhiltgen/docker-machine-kvm/releases/download/v0.10.0/docker-machine-driver-kvm-centos7 -o /usr/local/bin/docker-machine-driver-kvm
  chmod +x /usr/local/bin/docker-machine-driver-kvm

  systemctl enable libvirtd
  systemctl start libvirtd

  virsh net-list --all
  echo "======== KVM has been installed successfully ========"
}

function installAndStartMinishift() {
  echo "======== Start to install minishift ========"
  curl -Lo minishift.tgz https://github.com/minishift/minishift/releases/download/v1.34.2/minishift-1.34.2-linux-amd64.tgz
  tar -xvf minishift.tgz --strip-components=1
  chmod +x ./minishift
  mv ./minishift /usr/local/bin/minishift

  #Setup GitHub token for minishift
  if [ -z "$CHE_BOT_GITHUB_TOKEN" ]
  then
    echo "\$CHE_BOT_GITHUB_TOKEN is empty. Minishift start might fail with GitGub API rate limit reached."
  else
    echo "\$CHE_BOT_GITHUB_TOKEN is set, checking limits."
    GITHUB_RATE_REMAINING=$(curl -slL "https://api.github.com/rate_limit?access_token=$CHE_BOT_GITHUB_TOKEN" | jq .rate.remaining)
    if [ "$GITHUB_RATE_REMAINING" -gt 1000 ]
    then
      echo "Github rate greater than 1000. Using che-bot token for minishift startup."
      export MINISHIFT_GITHUB_API_TOKEN=$CHE_BOT_GITHUB_TOKEN
    else
      echo "Github rate is lower than 1000. *Not* using che-bot for minishift startup."
      echo "If minishift startup fails, please try again later."
    fi
  fi

  minishift version
  minishift config set memory 14GB
  minishift config set cpus 4

  echo "======== Launch minishift ========"
  minishift start

  oc login -u system:admin
  oc adm policy add-cluster-role-to-user cluster-admin developer
  oc login -u developer -p developer

  . "${SCRIPT_DIR}"/che-cert-generation.sh

  oc project default
  oc delete secret router-certs

  cat domain.crt domain.key > minishift.crt
  oc create secret tls router-certs --key=domain.key --cert=minishift.crt
  oc rollout status dc router
  oc rollout latest router
  oc rollout status dc router

  oc create namespace che

  cp rootCA.crt ca.crt
  oc create secret generic self-signed-certificate --from-file=ca.crt -n=che
  oc project che
}

function createTestUserAndObtainUserToken() {

  ### Create user and obtain token
  KEYCLOAK_URL=$(oc get checluster eclipse-che -o jsonpath='{.status.keycloakURL}')
  KEYCLOAK_BASE_URL="${KEYCLOAK_URL}/auth"

  ADMIN_USERNAME=admin
  ADMIN_PASS=admin
  TEST_USERNAME=admin

  echo "======== Getting admin token ========"
  ADMIN_ACCESS_TOKEN=$(curl -k -X POST $KEYCLOAK_BASE_URL/realms/master/protocol/openid-connect/token -H "Content-Type: application/x-www-form-urlencoded" -d "username=admin" -d "password=admin" -d "grant_type=password" -d "client_id=admin-cli" | jq -r .access_token)
  echo $ADMIN_ACCESS_TOKEN

  echo "========Creating user========"
  USER_JSON="{\"username\": \"${TEST_USERNAME}\",\"enabled\": true,\"emailVerified\": true,\"email\":\"test1@user.aa\"}"
  echo $USER_JSON

  curl -k -X POST $KEYCLOAK_BASE_URL/admin/realms/che/users -H "Authorization: Bearer ${ADMIN_ACCESS_TOKEN}" -H "Content-Type: application/json" -d "${USER_JSON}" -v
  USER_ID=$(curl -k -X GET $KEYCLOAK_BASE_URL/admin/realms/che/users?username=${TEST_USERNAME} -H "Authorization: Bearer ${ADMIN_ACCESS_TOKEN}" | jq -r .[0].id)
  echo "========User id: $USER_ID========"

  echo "========Updating password========"
  CREDENTIALS_JSON={\"type\":\"password\",\"value\":\"${TEST_USERNAME}\",\"temporary\":false}
  echo $CREDENTIALS_JSON

  curl -k -X PUT $KEYCLOAK_BASE_URL/admin/realms/che/users/${USER_ID}/reset-password -H "Authorization: Bearer ${ADMIN_ACCESS_TOKEN}" -H "Content-Type: application/json" -d "${CREDENTIALS_JSON}" -v
  export USER_ACCESS_TOKEN=$(curl -k -X POST $KEYCLOAK_BASE_URL/realms/che/protocol/openid-connect/token -H "Content-Type: application/x-www-form-urlencoded" -d "username=${TEST_USERNAME}" -d "password=${TEST_USERNAME}" -d "grant_type=password" -d "client_id=che-public" | jq -r .access_token)
  echo "========User Access Token: $USER_ACCESS_TOKEN "
}

createTestWorkspaceAndRunTest() {
  CHE_URL=$(oc get checluster eclipse-che -o jsonpath='{.status.cheURL}')

  ### Create directory for report
  cd /root/payload
  mkdir report
  REPORT_FOLDER=$(pwd)/report
  ### Run tests
  docker run --shm-size=1g --net=host  --ipc=host -v $REPORT_FOLDER:/tmp/e2e/report:Z \
  -e TS_SELENIUM_BASE_URL="$CHE_URL" \
  -e TS_SELENIUM_LOG_LEVEL=DEBUG \
  -e TS_SELENIUM_MULTIUSER=true \
  -e TS_SELENIUM_USERNAME="admin" \
  -e TS_SELENIUM_PASSWORD="admin" \
  -e TS_SELENIUM_DEFAULT_TIMEOUT=300000 \
  -e TS_SELENIUM_WORKSPACE_STATUS_POLLING=20000 \
  -e TS_SELENIUM_LOAD_PAGE_TIMEOUT=420000 \
  -e TEST_SUITE="test-all-devfiles" \
  -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
  quay.io/eclipse/che-e2e:nightly || IS_TESTS_FAILED=true
}

function archiveArtifacts() {
  JOB_NAME=$1
  DATE=$(date +"%m-%d-%Y-%H-%M")
  echo "Archiving artifacts from ${DATE} for ${JOB_NAME}/${BUILD_NUMBER}"
  cd /root/payload
  ls -la ./artifacts.key
  chmod 600 ./artifacts.key
  chown $(whoami) ./artifacts.key
  mkdir -p ./che/${JOB_NAME}/${BUILD_NUMBER}
  cp -R ./report ./che/${JOB_NAME}/${BUILD_NUMBER}/ | true
  rsync --password-file=./artifacts.key -Hva --partial --relative ./che/${JOB_NAME}/${BUILD_NUMBER} devtools@artifacts.ci.centos.org::devtools/
}

function installEpelRelease() {
  if yum repolist | grep epel; then
    echo "Epel already installed, skipping instalation."
  else
    #excluding mirror1.ci.centos.org
    echo "exclude=mirror1.ci.centos.org" >>/etc/yum/pluginconf.d/fastestmirror.conf
    echo "Installing epel..."
    yum install -d1 --assumeyes epel-release
    yum update --assumeyes -d1
  fi
}

function installJQ() {
  installEpelRelease
  yum install --assumeyes -d1 jq
}



set -x

export FAIL_MESSAGE="Build failed."

SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
export SCRIPT_DIR

# shellcheck disable=SC1090
. "${SCRIPT_DIR}"/../cico_functions.sh

load_jenkins_vars
install_deps
setup_environment

# Build & push.

export TAG="PR-${ghprbPullId}"
export IMAGE_NAME="quay.io/eclipse/che-devfile-registry:$TAG"
build_and_push

export FAIL_MESSAGE="Build passed. Image is available on $IMAGE_NAME"

# Install test deps
installOC
installKVM
installAndStartMinishift
installJQ


bash <(curl -sL https://www.eclipse.org/che/chectl/) --channel=next

cat >/tmp/che-cr-patch.yaml <<EOL
spec:
  server:
    devfileRegistryImage: $IMAGE_NAME
    selfSignedCert: true
EOL

echo "======= Che cr patch ======="
cat /tmp/che-cr-patch.yaml

# Start Che

if chectl server:start --listr-renderer=verbose -a operator -p openshift --k8spodreadytimeout=360000 --che-operator-cr-patch-yaml=/tmp/che-cr-patch.yaml; then
    echo "Started succesfully"
    oc get checluster -o yaml
else
    echo "======== oc get events ========"
    oc get events
    echo "======== oc get all ========"
    oc get all
    getOpenshiftLogs
    oc get checluster -o yaml || true
    exit 1337
fi

#Run tests

createTestUserAndObtainUserToken

createTestWorkspaceAndRunTest

getOpenshiftLogs

archiveArtifacts "che-devfile-registry-prcheck"
