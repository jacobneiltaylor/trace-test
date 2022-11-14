FROM golang:latest as builder
RUN mkdir -p /build
WORKDIR /build
COPY go.mod go.sum main.go ./
RUN go mod download && go mod verify
RUN go build -v -o /tmp/server ./...

FROM ubuntu:jammy as runner
ARG VERSION=1.24.0
ARG LOG_LEVEL
ENV ENVOY_LOG_LEVEL=${LOG_LEVEL:-info}
RUN apt-get update && apt-get -y --no-install-recommends upgrade
RUN apt-get -y --no-install-recommends install unzip supervisor jq curl lsb-release python3 python3-pip python-is-python3 
RUN python3 -m pip install --no-cache-dir --upgrade pip
RUN mkdir -p /opt/trace-test/bin; mkdir -p /opt/trace-test/etc
ENV PATH=/opt/trace-test/bin:$PATH
RUN curl https://func-e.io/install.sh | bash -s -- -b /opt/trace-test/bin
COPY --from=builder /tmp/server /opt/trace-test/bin/trace-test
RUN chmod +x /opt/trace-test/bin/trace-test; func-e use $VERSION
COPY ./config/supervisor.ini /opt/trace-test/etc/supervisor.ini
COPY ./config/${VERSION}_envoy.conf.yaml /opt/trace-test/etc/envoy.conf.yaml
EXPOSE 8080
CMD ["supervisord", "-c", "/opt/trace-test/etc/supervisor.ini"]
