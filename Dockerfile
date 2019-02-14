FROM golang:1.9-alpine as builder
RUN set -ex \
    && apk add --no-cache \
        bash gcc git musl-dev openssl rsync
ARG ORCHESTRATOR_VERSION=v3.0.14
ARG ORCHESTRATOR_REPO=https://github.com/github/orchestrator.git
RUN set -ex \
    && mkdir -p $GOPATH/src/github.com/github/orchestrator \
    && cd $GOPATH/src/github.com/github/orchestrator \
    && git init && git remote add origin $ORCHESTRATOR_REPO \
    && git fetch --tags \
    && git checkout $ORCHESTRATOR_VERSION
WORKDIR $GOPATH/src/github.com/github/orchestrator
RUN set -ex \
    && ls -l \
    && ./script/build

###############################################################################

FROM alpine:3.7
ENV DOCKERIZE_VERSION v0.6.1
RUN set -ex \
    && apk add --update --no-cache \
        curl \
        wget \
        tar \
        openssl \
    && mkdir /etc/orchestrator \
    && wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz -O- | \
        tar -C /usr/local/bin -xzv

COPY --from=builder /go/src/github.com/github/orchestrator/bin/ /usr/local/orchestrator/
COPY root/ /
EXPOSE 3000 10008
VOLUME [ "/var/lib/orchestrator" ]
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["/usr/local/bin/orchestrator", "-quiet", "-config", "/etc/orchestrator/orchestrator.conf.json", "http"]
