ARG RUBY_VERSION=3.1.1-slim-bullseye
ARG APP_ROOT=/app
ARG BUNDLER_VER=2.2.20
ARG SYSTEM_PACKAGES="curl gnupg1"
ARG BUILD_PACKAGES="build-essential libxml2-dev libxslt1-dev libc6-dev shared-mime-info"
ARG DEV_PACKAGES="git unzip"
ARG RUBY_PACKAGES="tzdata libjemalloc2"

# BASIC
FROM ruby:$RUBY_VERSION AS basic
ENV LANG C.UTF-8
ARG APP_ROOT
ARG BUILD_PACKAGES
ARG DEV_PACKAGES
ARG RUBY_PACKAGES
ARG SYSTEM_PACKAGES
ARG BUNDLER_VER
ENV APP_ROOT=${APP_ROOT}
ENV BUNDLER_VER=${BUNDLER_VER}
ENV SYSTEM_PACKAGES=${SYSTEM_PACKAGES}
ENV BUILD_PACKAGES=${BUILD_PACKAGES}
ENV DEV_PACKAGES=${DEV_PACKAGES}
ENV RUBY_PACKAGES=${RUBY_PACKAGES}
ENV HOME=${APP_ROOT}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
COPY docker-entrypoint.sh /
RUN chmod a+x /docker-entrypoint.sh
RUN set -x && apt-get update && apt-get install --no-install-recommends --yes ${SYSTEM_PACKAGES} \
     && apt-get update \
     && apt-get upgrade --yes \
     && apt-get install --no-install-recommends --yes ${BUILD_PACKAGES} \
     ${DEV_PACKAGES} \
     ${RUBY_PACKAGES} \
     && mkdir -p ${APP_ROOT} && adduser --system --gid 0 --uid 1001 --home ${APP_ROOT} appuser \
     && chgrp -R 0 ${APP_ROOT} && chmod -R g=u ${APP_ROOT} && chmod g=u /etc/passwd \
     && gem update --system && apt-get clean \
     && rm -rf /var/lib/apt/lists/*
RUN gem install bundler:$BUNDLER_VER
# Set a user to run
USER 1001
ENTRYPOINT ["/docker-entrypoint.sh"]
# set working folder
WORKDIR $APP_ROOT

FROM basic AS devspace
ENV REVIEWDOG_VERSION=v0.9.17
ENV BUNDLE_PATH /app/.bundle
# hadolint ignore=DL3002
USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN set -x && curl -sS -L https://github.com/client9/misspell/releases/download/v0.3.4/misspell_0.3.4_linux_64bit.tar.gz | tar xvzf - \
     && mv misspell /usr/local/bin/ \
     && curl -sS -L https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b /usr/local/bin/ $REVIEWDOG_VERSION
CMD ["/bin/bash"]
