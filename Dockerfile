ARG TOMCAT_VERSION=6.0.53

FROM asuuto/apache-installer:latest AS installer
ARG TOMCAT_VERSION
RUN /install-tomcat ${TOMCAT_VERSION}

FROM amazonlinux:2 AS final
LABEL maintainer="Nate Wilken <wilken@asu.edu>"
ARG TOMCAT_VERSION

RUN set -x && \
    yum update -y && \
    yum install -y java-1.7.0-openjdk-devel && \
    yum clean all && \
    rm -rf /var/cache/yum /var/log/yum.log

ENV JAVA_HOME /usr/lib/jvm/java-1.7.0

WORKDIR /usr/local

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

COPY --from=installer /software/apache-tomcat-${TOMCAT_VERSION} .

RUN set -x && \
    \
# sh removes env vars it doesn't support (ones with periods)
# https://github.com/docker-library/tomcat/issues/77
    find ./bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' '{}' + && \
    \
# fix permissions (especially for running as non-root)
# https://github.com/docker-library/tomcat/issues/35
    chmod -R +rX . && \
    chmod 777 logs temp work

EXPOSE 8080
CMD ["catalina.sh", "run"]
