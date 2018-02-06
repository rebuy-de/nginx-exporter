# nginx-exporter

[![Build Status](https://travis-ci.org/rebuy-de/nginx-exporter.svg?branch=master)](https://travis-ci.org/rebuy-de/nginx-exporter)
[![license](https://img.shields.io/github/license/rebuy-de/nginx-exporter.svg)]()
[![GitHub release](https://img.shields.io/github/release/rebuy-de/nginx-exporter.svg)]()

A meta nginx exporter that combines two different exporters

## References

* The mtail programm is based on
  [ndiazg/nginx-prometheus-exporter](https://github.com/ndiazg/nginx-prometheus-exporter).
* The status page exporter is from
  [discordianfish/nginx_exporter](https://github.com/discordianfish/nginx_exporter).


## Available Metrics

### From mtail

All metrics provide these labels: `vhost`, `method`, `code`, `content_type`.

* `nginx_requests_total` – Counter of processed requests.
* `nginx_request_duration_milliseconds_sum` – Sum of all response times (additional label: `le`).
* `nginx_response_size_bytes_sum` – Sum of all response body sizes.

The `le` label can be used to generate a histogram. The buckets currently have a
fixed size (`100ms`, `200ms`, `300ms`, `500ms`, `800ms`, `1300ms`, `2100ms`).

### From status page

* `nginx_connections_current` – Number of connections currently processed by nginx (labels: `state`)
* `nginx_connections_processed_total` – Number of connections processed by nginx (labels: `stage`)

Also there is `up` and `nginx_exporter_scrape_failures_total`.

## Configuration

### Nginx

#### Access Logs

The exporter needs a particular access logs format, since the default format
doesn't include response times. This needs to be specified in the `http`
section:

```nginx
log_format mtail '$host $remote_addr - $remote_user [$time_local] '
                 '"$request" $status $body_bytes_sent $request_time '
                 '"$http_referer" "$http_user_agent" "$content_type"';
```

The access logs needs to be enabled in each `server` secion:

```nginx
access_log /var/log/nginx/mtail/access.log mtail;
```

#### Status Page

The status page is disabled by default. We suggest to listen on a separate port, so the path doesn't clash with any existing resource:

```nginx
server {
    listen 8888;
    location /nginx_status {
      stub_status on;
      access_log  off;
      allow       127.0.0.1;
      deny        all;
    }
}
```

### Exporter

This exporter is configured via environment variables:

* `NGINX_ACCESS_LOGS` -- Path to the nginx access logs (eg
  `/var/log/nginx/mtail/access.log` in the example above).
* `NGINX_STATUS_URI` -- URI to the nginx status page (eg
  `http://localhost:8888/nginx_status` in the example above).

### Prometheus

The exporter provides two metric endpoints:

- `3093` -- mtail exporter
- `9113` -- status page exporter

### Kubernetes

The exporter is supposed to run as a sidecar. Here is an example config:

```yaml
apiVersion: extensions/v1beta1
kind: Deployment

metadata:
  name: my-nginx
  labels:
    app: my-nginx

spec:
  selector:
    matchLabels:
      app: my-nginx

  template:
    metadata:
      name: my-nginx
      labels:
        app: my-nginx
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "3093;9113"

    spec:
      containers:
      - name: "nginx"
        image: "my-nginx" # nginx image with modified config file

        volumeMounts:
        - name: mtail
          mountPath: /var/log/nginx/mtail

      - name: exporter
        image: quay.io/rebuy/nginx-exporter:v1.0.0

        ports:
        - containerPort: 3093
        - containerPort: 9113

        env:
        - name: NGINX_ACCESS_LOGS
          value: /var/log/nginx/mtail/access.log
        - name: NGINX_STATUS_URI
          value: http://localhost:8888/nginx_status

        volumeMounts:
        - name: mtail
          mountPath: /var/log/nginx/mtail

      volumes:
      - name: mtail
        emptyDir: {}
```
