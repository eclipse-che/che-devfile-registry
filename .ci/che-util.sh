#!/bin/bash
# shellcheck disable=SC2046,SC2164,SC2086,SC1090,SC2154

# Copyright (c) 2012-2020 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

function createTestWorkspaceAndRunTest() {
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

  export IS_TESTS_FAILED
}
