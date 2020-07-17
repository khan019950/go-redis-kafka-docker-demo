FROM golang:alpine As base

ENV GO111MODULE=on \
    CGO_ENABLED=1 \
    GOOS=linux \
    GOARCH=amd64

# Install required packaged
RUN apk add --update --no-cache git bash build-base xz librdkafka-dev pkgconf

# Chanhe working directory /build
WORKDIR /build

# Copy codes
COPY . .

# Download required modules
RUN go mod download

# Build
RUN go build -tags musl -installsuffix cgo -ldflags '-w -s -extldflags "-static"' -v -o /build/main /build/cmd/http-server/main.go

# Compress binary with upx
ADD https://github.com/upx/upx/releases/download/v3.96/upx-3.96-amd64_linux.tar.xz /usr/local
RUN xz -d -c /usr/local/upx-3.96-amd64_linux.tar.xz | \
    tar -xOf - upx-3.96-amd64_linux/upx > /bin/upx && \
    chmod a+x /bin/upx
RUN strip --strip-unneeded main
RUN upx main

# Layer 2- > Final layer
FROM scratch

# Copy content from base
COPY --from=base /build/* /

WORKDIR /

# entrypoint for container
ENTRYPOINT ["/main"]