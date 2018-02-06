FROM ndiazg/nginx-prometheus-exporter as mtail

FROM fish/nginx-exporter:v0.1.0 as status

FROM alpine:3.7

RUN set -x \
 && apk add --no-cache \
      supervisor

COPY --from=mtail /usr/local/bin/mtail /usr/local/bin/mtail
COPY --from=status /usr/local/bin/nginx_exporter /usr/local/bin/nginx_exporter
COPY assets/supervisord.conf /etc/supervisord.conf
COPY assets/nginx.mtail /etc/mtail/nginx.mtail

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
