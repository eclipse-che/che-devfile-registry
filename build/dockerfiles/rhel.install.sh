#!/bin/bash
#
# Copyright (c) 2018-2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
set -x

microdnf --disablerepo=fedora30-updates --disablerepo=fedora30-secondary-updates install -y findutils bash wget yum gzip git tar python3-six python3-pip && microdnf -y clean all
microdnf --enablerepo=fedora30-updates --enablerepo=fedora30-secondary-updates install -y skopeo jq && microdnf update -y skopeo containers-common jq oniguruma && microdnf -y clean all
# install yq (depends on jq and pyyaml - if jq and pyyaml not already installed, this will try to compile it)
if [[ -f /tmp/root-local.tgz ]] || [[ ${BOOTSTRAP} == "true" ]]; then
    mkdir -p /root/.local
    if [[ -f /tmp/root-local.tgz ]]; then
        tar xf /tmp/root-local.tgz -C /root/.local/
        rm -fr /tmp/root-local.tgz
    fi
    /usr/bin/pip3.6 install --user yq jsonschema
    # could be installed in /opt/app-root/src/.local/bin or /root/.local/bin
    for d in /opt/app-root/src/.local /root/.local; do
        if [[ -d ${d} ]]; then
            cp ${d}/bin/yq ${d}/bin/jsonschema /usr/local/bin/
            pushd ${d}/lib/python3.6/site-packages/ >/dev/null || exit 1
            cp -r PyYAML* xmltodict* yaml* yq* jsonschema* /usr/lib/python3.6/site-packages/
            popd >/dev/null || exit 1
        fi
    done
    chmod -c +x /usr/local/bin/*
else
    /usr/bin/pip3.6 install yq jsonschema
fi
ln -s /usr/bin/python3.6 /usr/bin/python
# test install worked
for d in python yq jq jsonschema; do echo -n "$d: "; $d --version; done

# for debugging only
# microdnf install -y util-linux && whereis python pip jq yq && python --version && jq --version && yq --version
