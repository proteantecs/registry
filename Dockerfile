# Multi-stage build to compile registry from source with latest Go
FROM golang:1.23-alpine AS builder

RUN apk add --no-cache git ca-certificates

# Clone and build the registry from source with latest Go (fixes vulnerability)
WORKDIR /src
RUN git clone --depth 1 --branch v3.0.0 https://github.com/distribution/distribution.git .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /registry ./cmd/registry

# Test the binary works in builder
RUN /registry --version

# Final stage - minimal runtime image
FROM alpine:3.21

RUN apk add --no-cache ca-certificates

# Copy the compiled binary from builder stage
COPY --from=builder /registry /bin/registry

COPY ./config-example.yml /etc/distribution/config.yml

ENV OTEL_TRACES_EXPORTER=none

VOLUME ["/var/lib/registry"]
EXPOSE 5000

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/etc/distribution/config.yml"]