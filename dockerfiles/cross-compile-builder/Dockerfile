ARG BASE_IMAGE=debian:bookworm-slim
ARG IMAGE_PLATFORM=linux/amd64
FROM --platform=${IMAGE_PLATFORM} ${BASE_IMAGE}

ARG GO_VERSION=latest

ARG GCC_ARM_VERSION=gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabi
ARG GCC_ARM_URL=https://releases.linaro.org/components/toolchain/binaries/5.3-2016.05/arm-linux-gnueabi/${GCC_ARM_VERSION}.tar.xz

ARG GCC_AARCH64_VERSION=gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu
ARG GCC_AARCH64_URL=https://releases.linaro.org/components/toolchain/binaries/7.4-2019.02/aarch64-linux-gnu/${GCC_AARCH64_VERSION}.tar.xz

ENV GOPATH=/go
ENV PATH="/go/bin:/usr/local/go/bin:${PATH}"

WORKDIR /app

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gcc \
        g++ \
        git \
        make \
        xz-utils && \
    if [[ "${GO_VERSION}" == "latest" ]]; then \
        go_filename="$(curl -fsSL 'https://go.dev/dl/?mode=json' | \
            grep -m 1 -o 'go[0-9.]*\.linux-amd64\.tar\.gz')"; \
        go_download_url="https://go.dev/dl/${go_filename}"; \
    else \
        go_download_url="https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"; \
    fi && \
    curl -fsSL "${go_download_url}" | tar -xz -C /usr/local && \
    ln -sf /usr/local/go/bin/go /usr/local/bin/go && \
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt && \
    curl -fsSL "${GCC_ARM_URL}" | tar -xJ -C /opt && \
    curl -fsSL "${GCC_AARCH64_URL}" | tar -xJ -C /opt && \
    apt-get purge -y --auto-remove xz-utils && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
