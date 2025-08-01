FROM alpine:3.21

RUN apk add --no-cache ca-certificates

RUN set -eux; \
# Check https://github.com/distribution/distribution/releases for latest version
# Updated to use a newer version that should have Go vulnerability fixes
    version='3.0.1'; \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
       x86_64)  arch='amd64';   sha256='UPDATE_HASH_HERE' ;; \
       aarch64) arch='arm64';   sha256='UPDATE_HASH_HERE' ;; \
       armhf)   arch='armv6';   sha256='UPDATE_HASH_HERE' ;; \
       armv7)   arch='armv7';   sha256='UPDATE_HASH_HERE' ;; \
       ppc64le) arch='ppc64le'; sha256='UPDATE_HASH_HERE' ;; \
       s390x)   arch='s390x';   sha256='UPDATE_HASH_HERE' ;; \
       riscv64) arch='riscv64'; sha256='UPDATE_HASH_HERE' ;; \
       *) echo >&2 "error: unsupported architecture: $apkArch"; exit 1 ;; \
    esac; \
    wget -O registry.tar.gz "https://github.com/distribution/distribution/releases/download/v${version}/registry_${version}_linux_${arch}.tar.gz"; \
    echo "$sha256 *registry.tar.gz" | sha256sum -c -; \
    tar --extract --verbose --file registry.tar.gz --directory /bin/ registry; \
    rm registry.tar.gz; \
    registry --version

COPY ./config-example.yml /etc/distribution/config.yml

ENV OTEL_TRACES_EXPORTER=none

VOLUME ["/var/lib/registry"]
EXPOSE 5000

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/etc/distribution/config.yml"]
