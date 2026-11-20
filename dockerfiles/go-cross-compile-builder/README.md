# Cross Compile Builder

Build image for packaging Go projects with C toolchains, especially Linux ARM and ARM64 cross compilation with CGO enabled.

## Build

```bash
docker build -t go-cross-compile-builder:latest .
```

The image defaults to `linux/amd64` because the bundled Linaro cross toolchains are x86_64 binaries. The base image is `debian:jessie-slim` by default. It uses glibc 2.19 to keep native CGO builds compatible with the previous Ubuntu 16.04/glibc 2.23 baseline. Jessie is end-of-life, so the Dockerfile uses archived Debian repositories. The toolchain defaults use a tested GitHub mirror because the former Linaro release URLs are no longer downloadable. Override `BASE_IMAGE`, `IMAGE_PLATFORM`, `GCC_ARM_URL`, or `GCC_AARCH64_URL` when required.

The Linaro archives ship unstripped host binaries and debug info in the target sysroot. The build strips them in the same layer and removes components that CGO C/C++ builds do not use (Fortran, gdb, docs, man pages, locales, and the Go `test`, `api`, `doc`, and `misc` directories). This shrinks the image from about 2.5 GB to about 0.85 GB. With the same Go version, produced binaries are byte-identical, except that static ARM (32-bit) links may order ARM/Thumb interworking veneers differently; section layout and behavior are unchanged. Install `gdb` or `gfortran` separately if a build ever needs them.

Go defaults to the latest stable release from `go.dev`. Pin a specific version when reproducible builds are required:

```bash
docker build --build-arg GO_VERSION=1.24.0 -t go-cross-compile-builder:latest .
```

## Usage

```makefile
BUILD_IMAGE ?= go-cross-compile-builder:latest

build-linux-arm64:
        docker run --rm -it \
        -v $(CURR_DIR):/app \
        -v $$HOME/go/pkg/mod:/go/pkg/mod \
        -w /app \
        -e GOOS=linux \
        -e GOARCH=arm64 \
        -e CGO_ENABLED=1 \
        -e CC=/opt/gcc-linaro-5.3.1-2016.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-gcc \
        -e CXX=/opt/gcc-linaro-5.3.1-2016.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-g++ \
        $(BUILD_IMAGE) \
        go build -ldflags="-s -w" -v -buildvcs=false -o ${ARM64_OUTPUT} ${CMD_DIR}

build-linux-arm:
        docker run --rm -it \
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

build-windows-amd64:
        docker run --rm -it \
        -v $(CURR_DIR):/app \
        -v $$HOME/go/pkg/mod:/go/pkg/mod \
        -w /app \
        -e GOOS=windows \
        -e GOARCH=amd64 \
        -e CGO_ENABLED=1 \
        $(BUILD_IMAGE) \
        go build -ldflags="-s -w" -v -buildvcs=false -o ${AMD64_OUTPUT} ${CMD_DIR}
```
