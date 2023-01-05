#
# Copyright (c) 2018-2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
FROM docker.io/node:16.13.0-alpine3.14 AS builder

ARG VERSION

RUN apk add --no-cache py-pip jq bash wget git skopeo && pip install yq

COPY ./build/scripts /build/
COPY ./devfiles /build/devfiles
WORKDIR /build/

RUN ./check_mandatory_fields.sh devfiles

RUN ./index.sh > /build/devfiles/index.json
RUN ./generate_devworkspace_templates.sh
RUN ./update_devworkspace_templates.sh $VERSION
RUN ./list_referenced_images.sh devfiles > /build/devfiles/external_images.txt
RUN chmod -R g+rwX /build/devfiles
RUN chmod -R g+rwX /build/resources

FROM docker.io/httpd:2.4.43-alpine AS registry
RUN apk add --no-cache bash && \
    # Allow htaccess
    sed -i 's|    AllowOverride None|    AllowOverride All|' /usr/local/apache2/conf/httpd.conf && \
    sed -i 's|Listen 80|Listen 8080|' /usr/local/apache2/conf/httpd.conf && \
    mkdir -m 777 /usr/local/apache2/htdocs/devfiles && \
    mkdir -p /var/www && ln -s /usr/local/apache2/htdocs /var/www/html && \
    chmod -R g+rwX /usr/local/apache2 && \
    echo "ServerName localhost" >> /usr/local/apache2/conf/httpd.conf && \
    echo "LimitRequestFieldSize 32768" >> /usr/local/apache2/conf/httpd.conf && \
    apk add --no-cache coreutils
COPY .htaccess README.md /usr/local/apache2/htdocs/
COPY --from=builder /build/devfiles /usr/local/apache2/htdocs/devfiles
COPY --from=builder /build/resources /usr/local/apache2/htdocs/resources
COPY ./images /usr/local/apache2/htdocs/images
COPY ./build/dockerfiles/entrypoint.sh /usr/bin/
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["httpd-foreground"]

# Offline registry: download project zips and place them in /build/resources
FROM builder AS offline-builder
RUN ./cache_projects.sh devfiles resources && \
    ./cache_images.sh devfiles resources && \
    chmod -R g+rwX /build

# Offline registry: copy updated devfile.yamls and cached projects
FROM registry AS offline-registry
COPY --from=offline-builder /build/devfiles /usr/local/apache2/htdocs/devfiles
COPY --from=offline-builder /build/resources /usr/local/apache2/htdocs/resources
