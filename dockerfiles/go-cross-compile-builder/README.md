# Cross Compile Builder

Build image for packaging Go projects with C toolchains, especially Linux ARM and ARM64 cross compilation with CGO enabled.

## Build

The Dockerfile needs no build context, so it can be piped in:

```bash
docker build -t go-cross-compile-builder:latest - < Dockerfile
```

The image defaults to `linux/amd64` because the bundled Linaro cross toolchains are x86_64 binaries. The base image is `debian:jessie-slim` by default. It uses glibc 2.19 to keep native CGO builds compatible with the previous Ubuntu 16.04/glibc 2.23 baseline. Jessie is end-of-life, so the Dockerfile uses archived Debian repositories. Override `BASE_IMAGE` or `IMAGE_PLATFORM` when required.

## Toolchains

| Target | Toolchain | `CC` |
|---|---|---|
| `GOARCH=arm` | Linaro GCC 5.3.1 (2016.05) | `/opt/gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabi/bin/arm-linux-gnueabi-gcc` |
| `GOARCH=arm64` | Linaro GCC 7.4.1 (2019.02) | `/opt/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gcc` |
| `GOARCH=amd64` | Debian Jessie GCC 4.9 | default `gcc` |

Linaro no longer serves these releases, so the defaults download from mirrors: the ARM toolchain from a GitHub release mirror and the ARM64 toolchain from Armbian (`https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/_toolchain/` serves the same file). Every archive is verified against a pinned SHA-256, so the build fails instead of installing a different file. When overriding `GCC_ARM_URL` or `GCC_AARCH64_URL`, also set `GCC_ARM_SHA256` or `GCC_AARCH64_SHA256`.

The Linaro archives ship unstripped host binaries and debug info in the target sysroot. The build strips them in the same layer and removes components that CGO C/C++ builds do not use (Fortran, gdb, docs, man pages, locales, and the Go `test`, `api`, `doc`, and `misc` directories). With the same Go version, produced binaries are byte-identical, except that static ARM (32-bit) links may order ARM/Thumb interworking veneers differently; section layout and behavior are unchanged. Install `gdb` or `gfortran` separately if a build ever needs them.

Go defaults to the latest stable release from `go.dev`. Pin a specific version when reproducible builds are required:

```bash
docker build --build-arg GO_VERSION=1.24.0 -t go-cross-compile-builder:latest - < Dockerfile
```

## Usage

```makefile
BUILD_IMAGE ?= go-cross-compile-builder:latest

build-linux-arm64:
	docker run --rm --platform linux/amd64 \
	-v $(CURR_DIR):/app \
	-v $$HOME/go/pkg/mod:/go/pkg/mod \
	-w /app \
	-e GOOS=linux \
	-e GOARCH=arm64 \
	-e CGO_ENABLED=1 \
	-e CC=/opt/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gcc \
	-e CXX=/opt/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-g++ \
	$(BUILD_IMAGE) \
	go build -ldflags="-s -w" -v -buildvcs=false -o ${ARM64_OUTPUT} ${CMD_DIR}

build-linux-arm:
	docker run --rm --platform linux/amd64 \
	-v $(CURR_DIR):/app \
	-v $$HOME/go/pkg/mod:/go/pkg/mod \
	-w /app \
	-e GOOS=linux \
	-e GOARCH=arm \
	-e CGO_ENABLED=1 \
	-e CC=/opt/gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabi/bin/arm-linux-gnueabi-gcc \
	-e CXX=/opt/gcc-linaro-5.3.1-2016.05-x86_64_arm-linux-gnueabi/bin/arm-linux-gnueabi-g++ \
	$(BUILD_IMAGE) \
	go build -ldflags="-s -w" -v -buildvcs=false -o ${ARM_OUTPUT} ${CMD_DIR}

build-linux-amd64:
	docker run --rm --platform linux/amd64 \
	-v $(CURR_DIR):/app \
	-v $$HOME/go/pkg/mod:/go/pkg/mod \
	-w /app \
	-e GOOS=linux \
	-e GOARCH=amd64 \
	-e CGO_ENABLED=1 \
	$(BUILD_IMAGE) \
	go build -ldflags="-s -w" -v -buildvcs=false -o ${AMD64_OUTPUT} ${CMD_DIR}
```

Projects that use this image keep a copy at `docker/Dockerfile.go-cross` and build it with `make build-image`. Keep those copies identical to this file.
