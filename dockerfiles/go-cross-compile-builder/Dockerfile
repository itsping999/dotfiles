ARG BASE_IMAGE=debian:jessie-slim
ARG IMAGE_PLATFORM=linux/amd64
FROM --platform=${IMAGE_PLATFORM} ${BASE_IMAGE}

ARG GO_VERSION=latest

# Linaro no longer serves these releases, so the defaults point at mirrors.
# Each archive is pinned by SHA-256; override the URL and checksum together.
ARG GCC_ARM_URL=https://github.com/YuzukiHD/sunxi-bsp-toolchains/releases/download/1.0.0/gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabi.tar.xz
ARG GCC_ARM_SHA256=77cccd433d680251c8b9bfa01890cb6921548513a39fac35c1f4b9f0a47e5aa4
ARG GCC_AARCH64_URL=https://dl.armbian.com/_toolchain/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu.tar.xz
ARG GCC_AARCH64_SHA256=27f1dc2c491ed61ae8f0d4b0c11de59cd2f7dd9c94761ee7153006fcac1bf9ab

ENV GOPATH=/go
ENV PATH="/go/bin:/usr/local/go/bin:${PATH}"

WORKDIR /app

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN download() { \
        local url="$1" output="$2" attempt; \
        rm -f "${output}"; \
        for attempt in 1 2 3 4 5 6 7 8; do \
            if curl -fsSL --continue-at - --output "${output}" "${url}"; then \
                return 0; \
            fi; \
            sleep 2; \
        done; \
        echo "failed to download ${url}" >&2; \
        return 1; \
    } && \
    install_toolchain() { \
        local url="$1" sha256="$2" archive=/tmp/toolchain.tar.xz; \
        download "${url}" "${archive}" && \
        echo "${sha256}  ${archive}" | sha256sum -c - && \
        tar -xJf "${archive}" -C /opt && \
        rm -f "${archive}"; \
    } && \
    sed -i '/^deb /d' /etc/apt/sources.list && \
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
    download "${go_download_url}" /tmp/go.tar.gz && \
    tar -xzf /tmp/go.tar.gz -C /usr/local && \
    ln -sf /usr/local/go/bin/go /usr/local/bin/go && \
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt && \
    install_toolchain "${GCC_ARM_URL}" "${GCC_ARM_SHA256}" && \
    install_toolchain "${GCC_AARCH64_URL}" "${GCC_AARCH64_SHA256}" && \
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
