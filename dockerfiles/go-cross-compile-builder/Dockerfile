ARG BASE_IMAGE=debian:jessie-slim
ARG IMAGE_PLATFORM=linux/amd64
FROM --platform=${IMAGE_PLATFORM} ${BASE_IMAGE}

ARG GO_VERSION=latest

ARG GCC_ARM_URL=https://github.com/YuzukiHD/sunxi-bsp-toolchains/releases/download/1.0.0/gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabi.tar.xz
ARG GCC_AARCH64_URL=https://github.com/YuzukiHD/sunxi-bsp-toolchains/releases/download/1.0.0/gcc-linaro-5.3.1-2016.05-x86_64_aarch64-linux-gnu.tar.xz

ENV GOPATH=/go
ENV PATH="/go/bin:/usr/local/go/bin:${PATH}"

WORKDIR /app

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN sed -i '/^deb /d' /etc/apt/sources.list && \
    printf '%s\n' \
        'deb [trusted=yes] http://archive.debian.org/debian jessie main' \
        'deb [trusted=yes] http://archive.debian.org/debian-security jessie/updates main' \
        > /etc/apt/sources.list && \
    apt-get -o Acquire::Check-Valid-Until=false \
        -o Acquire::Retries=5 update && \
    apt-get -o Acquire::AllowInsecureRepositories=true \
        -o Acquire::Retries=5 \
        --allow-unauthenticated install -y --no-install-recommends \
        ca-certificates \
        curl \
        gcc \
        g++ \
        git \
        make \
        xz-utils && \
    if [[ "${GO_VERSION}" == "latest" ]]; then \
        curl -fsSL --retry 5 --retry-delay 2 \
            'https://go.dev/dl/?mode=json' -o /tmp/go-releases.json && \
        go_filename="$(grep -m 1 -o 'go[0-9.]*\.linux-amd64\.tar\.gz' \
            /tmp/go-releases.json)" && \
        go_download_url="https://dl.google.com/go/${go_filename}"; \
    else \
        go_download_url="https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz"; \
    fi && \
    go_archive=/tmp/go.tar.gz && \
    rm -f "${go_archive}" && \
    for attempt in 1 2 3 4 5 6 7 8; do \
        if curl -fsSL --continue-at - --output "${go_archive}" \
            "${go_download_url}"; then \
            break; \
        fi; \
        if [[ "${attempt}" == "8" ]]; then \
            exit 1; \
        fi; \
        sleep 2; \
    done && \
    tar -xzf "${go_archive}" -C /usr/local && \
    ln -sf /usr/local/go/bin/go /usr/local/bin/go && \
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt && \
    for attempt in 1 2 3 4 5 6 7 8; do \
        if curl -fsSL --retry 5 --retry-delay 2 "${GCC_ARM_URL}" | \
            tar -xJ -C /opt; then \
            break; \
        fi; \
        if [[ "${attempt}" == "8" ]]; then \
            exit 1; \
        fi; \
        sleep 2; \
    done && \
    for attempt in 1 2 3 4 5 6 7 8; do \
        if curl -fsSL --retry 5 --retry-delay 2 "${GCC_AARCH64_URL}" | \
            tar -xJ -C /opt; then \
            break; \
        fi; \
        if [[ "${attempt}" == "8" ]]; then \
            exit 1; \
        fi; \
        sleep 2; \
    done && \
    # The Linaro releases ship unstripped host binaries and debug info in the
    # target sysroot (about 2 GB). Strip them in this same layer and drop the
    # parts that CGO C/C++ builds never use (Fortran, gdb, docs, locales).
    for toolchain in /opt/gcc-linaro-*; do \
        gcc_path="$(ls "${toolchain}"/bin/*-gcc | head -n 1)" && \
        triplet="$(basename "${gcc_path}" -gcc)" && \
        rm -rf "${toolchain:?}"/share/{doc,info,man,locale,dejagnu,gdb} \
            "${toolchain:?}/bin/${triplet}-gdb" \
            "${toolchain:?}/bin/${triplet}-gfortran" \
            "${toolchain:?}"/libexec/gcc/"${triplet}"/*/f951 \
            "${toolchain:?}/${triplet}/libc/usr/share" && \
        find "${toolchain}/bin" "${toolchain}/libexec" "${toolchain}/${triplet}/bin" \
            -type f -perm -u+x -exec sh -c \
            'head -c 4 "$1" | grep -q ELF && strip --strip-unneeded "$1" 2>/dev/null || true' \
            _ {} \; && \
        find "${toolchain}/${triplet}" "${toolchain}/lib" -type f \
            \( -name '*.so*' -o -name '*.a' -o -name '*.o' \) \
            -exec sh -c '"$0" --strip-debug "$1" 2>/dev/null || true' \
            "${toolchain}/bin/${triplet}-strip" {} \; || exit 1; \
    done && \
    rm -rf /usr/local/go/{test,api,doc,misc} && \
    apt-get purge -y --auto-remove xz-utils && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
