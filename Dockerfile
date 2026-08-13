# syntax=docker/dockerfile:1

# linux/amd64 manifest digest, not the mutable multi-platform tag.
FROM node:16.20.2-bullseye-slim@sha256:d0612de981085d97da2a3e65ee77e806063f4238262d6f5855fd6564584cf1c0 AS build

ARG DEBIAN_SNAPSHOT=20230824T000000Z
ARG FLUTTER_VERSION=3.7.12
ARG FLUTTER_REVISION=4d9e56e694b656610ab87fcf2efbcd226e0ed8cf
ARG FLUTTER_ENGINE_REVISION=1a65d409c7a1438a34d21b60bf30a6fd5db59314
ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    PUB_CACHE=/opt/pub-cache \
    SOURCE_DATE_EPOCH=1682509492 \
    TAR_OPTIONS=--no-same-owner \
    PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}

RUN printf '%s\n' \
      "deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT} bullseye main" \
      "deb [check-valid-until=no] http://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT} bullseye-security main" \
      > /etc/apt/sources.list \
    && rm -f /etc/apt/sources.list.d/* \
    && apt-get -o Acquire::Check-Valid-Until=false update \
    && apt-get install --yes --no-install-recommends ca-certificates curl git tar unzip xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && test "$(node --version)" = "v16.20.2" \
    && test "$(yarn --version)" = "1.22.19"

RUN git init /opt/flutter \
    && git -C /opt/flutter remote add origin https://github.com/flutter/flutter.git \
    && git -C /opt/flutter fetch --depth=1 origin \
      "refs/tags/${FLUTTER_VERSION}:refs/tags/${FLUTTER_VERSION}" \
    && git -C /opt/flutter checkout --detach "refs/tags/${FLUTTER_VERSION}" \
    && test "$(git -C /opt/flutter rev-parse HEAD)" = "${FLUTTER_REVISION}" \
    && test "$(cat /opt/flutter/bin/internal/engine.version)" = "${FLUTTER_ENGINE_REVISION}" \
    && git config --global --add safe.directory /opt/flutter \
    && flutter config --no-analytics --enable-web \
    && flutter precache --web \
    && flutter --version | grep --fixed-strings "Flutter ${FLUTTER_VERSION}"

WORKDIR /work
COPY rustdesk-source-47a7b7313bb906ebdae36bd16838bdefa8853639.tar /work/upstream-source.tar
COPY integration/resources-web-js/ /work/integration-js/
COPY . /work/disclosure/
COPY SOURCE.html /work/SOURCE.html

RUN printf '%s  %s\n' \
      f943ce011eb2f8dc3056326cfb265e4bcf3721daea5512e4b57181ffd46f3950 \
      /work/upstream-source.tar \
      | sha256sum --check --strict \
    && mkdir /work/upstream-source \
    && tar -xf /work/upstream-source.tar -C /work/upstream-source

# Start from the complete fixed upstream tree, overlay this API's modified JS
# sources, and delete all precompiled JS before rebuilding.
RUN cp -a /work/upstream-source /work/build-source \
    && rm -rf /work/build-source/flutter/web/js \
    && cp -a /work/integration-js /work/build-source/flutter/web/js \
    && rm -rf /work/build-source/flutter/web/js/dist /work/build-source/flutter/web/js/node_modules \
    && yarn --cwd /work/build-source/flutter/web/js install --frozen-lockfile --non-interactive \
    && yarn --cwd /work/build-source/flutter/web/js build \
    && rm -rf /work/build-source/flutter/web/js/node_modules

RUN cd /work/build-source/flutter \
    && flutter pub get \
    && flutter build web --release --base-href /webclient/ \
    && printf '%s  %s\n' \
      dc012d2e7a91c43eb753aa982a8a78f1c02dd86ca9bcf9258091dc67bcaccb5f \
      build/web/main.dart.js \
      | sha256sum --check --strict

COPY postprocess.mjs /work/postprocess.mjs
RUN node /work/postprocess.mjs \
      /work/build-source/flutter/build/web \
      /work/SOURCE.html \
      /work/disclosure/NOTICE \
      /work/upstream-source/LICENCE \
    && cp -a /work/disclosure /work/build-source/flutter/build/web/corresponding-source \
    && find /work/build-source/flutter/build/web -exec touch -h -d "@${SOURCE_DATE_EPOCH}" {} +

FROM scratch AS artifact
COPY --from=build /work/build-source/flutter/build/web/ /
