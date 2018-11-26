FROM alpine:3.8 as mtail

ENV GOPATH     /go
ENV PATH       /go/bin:$PATH

RUN apk add --no-cache --update musl musl-dev go git bash make

RUN mkdir -p  /go/src/github.com/google/ && \
    git clone https://github.com/google/mtail.git /go/src/github.com/google/mtail && \
    cd /go/src/github.com/google/mtail && \
    git checkout v3.0.0-rc17 && \
    make install_deps && make install

RUN ls -la /go/bin

FROM fish/nginx-exporter:v0.1.0 as status

FROM alpine:3.8

RUN apk add --no-cache supervisor

COPY --from=mtail /go/bin/mtail /usr/local/bin/mtail
COPY --from=status /usr/local/bin/nginx_exporter /usr/local/bin/nginx_exporter
COPY assets/merger.yaml /etc/exporter-merger.yaml
COPY assets/supervisord.conf /etc/supervisord.conf
COPY assets/nginx.mtail /etc/mtail/nginx.mtail
ADD https://github.com/rebuy-de/exporter-merger/releases/download/v0.1.0/exporter-merger-v0.1.0-linux-amd64 /usr/local/bin/exporter-merger

RUN chmod +x /usr/local/bin/exporter-merger

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
