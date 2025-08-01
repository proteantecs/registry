# Multi-stage build to compile registry from source with latest Go
FROM golang:1.23-alpine AS builder

RUN apk add --no-cache git ca-certificates

# Clone and build the registry from source with latest Go (fixes vulnerability)
RUN set -eux; \
    git clone --depth 1 --branch v3.0.0 https://github.com/distribution/distribution.git /src; \
    cd /src; \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o registry ./cmd/registry

# Final stage - minimal runtime image
FROM alpine:3.21

RUN apk add --no-cache ca-certificates

# Copy the compiled binary from builder stage and make it executable
COPY --from=builder /src/registry /bin/registry
RUN chmod +x /bin/registry

# Verify the binary works
RUN registry --version

COPY ./config-example.yml /etc/distribution/config.yml

ENV OTEL_TRACES_EXPORTER=none

VOLUME ["/var/lib/registry"]
EXPOSE 5000

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/etc/distribution/config.yml"]