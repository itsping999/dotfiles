# Cross Compile Builder

Build image for packaging Go projects with C toolchains, especially Linux ARM and ARM64 cross compilation with CGO enabled.

## Build

```bash
docker build -t cross-compile-builder .
```

The image defaults to `linux/amd64` because the bundled Linaro cross toolchains are x86_64 binaries. The base image uses `docker.1ms.run` by default and can be overridden with `BASE_IMAGE` or `IMAGE_PLATFORM` build args.

Go defaults to the latest stable release from `go.dev`. Pin a specific version when reproducible builds are required:

```bash
docker build --build-arg GO_VERSION=1.24.0 -t cross-compile-builder .
```

## Usage

```makefile
build-linux-arm64:
        docker run --rm -it \
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
