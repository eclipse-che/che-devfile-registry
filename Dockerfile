#
# Copyright (c) 2018-2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
FROM mikefarah/yq as builder
RUN apk add --no-cache bash

COPY .htaccess README.md *.sh /build/
COPY /devfiles /build/devfiles
WORKDIR /build/
RUN ./index.sh > /build/devfiles/index.json

FROM registry.centos.org/centos/httpd-24-centos7
RUN mkdir /var/www/html/devfiles
COPY --from=builder /build/ /var/www/html/
USER 0
RUN chmod -R g+rwX /var/www/html/devfiles
