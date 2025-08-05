# syntax=docker/dockerfile:1

ARG BASE_IMAGE=mirror.gcr.io/ubuntu:22.04

# -------------------------------
# Download VOICEVOX ENGINE
# -------------------------------
FROM ${BASE_IMAGE} AS download-engine-env
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /work

RUN apt-get update && \
    apt-get install -y curl p7zip-full && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 固定値：RELEASE情報
ENV VOICEVOX_ENGINE_REPOSITORY=VOICEVOX/voicevox_engine
ENV VOICEVOX_ENGINE_VERSION=0.24.1
ENV VOICEVOX_ENGINE_TARGET=linux-cpu-x64

RUN set -eux && \
    LIST_NAME=voicevox_engine-${VOICEVOX_ENGINE_TARGET}-${VOICEVOX_ENGINE_VERSION}.7z.txt && \
    curl -fLO --retry 3 --retry-delay 5 "https://github.com/${VOICEVOX_ENGINE_REPOSITORY}/releases/download/${VOICEVOX_ENGINE_VERSION}/${LIST_NAME}" && \
    awk \
        -v "repo=${VOICEVOX_ENGINE_REPOSITORY}" \
        -v "tag=${VOICEVOX_ENGINE_VERSION}" \
        '{ print "url = \"https://github.com/" repo "/releases/download/" tag "/" $0 "\"\noutput = \"" $0 "\"" }' \
        "$LIST_NAME" > ./curl.txt && \
    curl -fL --retry 3 --retry-delay 5 --parallel --config ./curl.txt && \
    7zr x "$(head -1 "./$LIST_NAME")" && \
    mv ./${VOICEVOX_ENGINE_TARGET} /opt/voicevox_engine && \
    rm -rf ./*

# -------------------------------
# Runtime 環境
# -------------------------------
FROM ${BASE_IMAGE} AS runtime-env
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /opt/voicevox_engine

RUN apt-get update && \
    apt-get install -y curl gosu && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    useradd --create-home user

COPY --from=download-engine-env /opt/voicevox_engine /opt/voicevox_engine

# Resource README ダウンロード（v0.24.1 対応）
ENV VOICEVOX_RESOURCE_VERSION=0.24.1
RUN curl -fLo "/opt/voicevox_engine/README.md" --retry 3 --retry-delay 5 \
    "https://raw.githubusercontent.com/VOICEVOX/voicevox_resource/${VOICEVOX_RESOURCE_VERSION}/engine/README.md"

# エントリースクリプト作成
COPY --chmod=775 <<EOF /entrypoint.sh
#!/bin/bash
set -eux
cat /opt/voicevox_engine/README.md > /dev/stderr
exec "\$@"
EOF

ENTRYPOINT ["/entrypoint.sh"]
CMD ["gosu", "user", "/opt/voicevox_engine/run", "--host", "0.0.0.0"]

# -------------------------------
# GPU対応版（Renderでは未使用）
# -------------------------------
# FROM runtime-env AS runtime-nvidia-env
# CMD ["gosu", "user", "/opt/voicevox_engine/run", "--use_gpu", "--host", "0.0.0.0"]
