# Kong Configuration Template
# This template defines the initial Kong services and routes

_format_version: "3.0"

services:
%{ for service in services ~}
  - name: ${service.name}
    url: ${service.url}
    routes:
      - name: ${service.name}-route
        paths:
          - ${service.path}
        methods:
          - GET
          - POST
          - PUT
          - DELETE
          - PATCH
        strip_path: ${service.strip_path}
        preserve_host: ${service.preserve_host}
    plugins:
      - name: cors
        config:
          origins:
            - "*"
          methods:
            - GET
            - POST
            - PUT
            - DELETE
            - PATCH
            - OPTIONS
          headers:
            - Accept
            - Accept-Version
            - Content-Length
            - Content-MD5
            - Content-Type
            - Date
            - X-Auth-Token
          exposed_headers:
            - X-Auth-Token
          credentials: true
          max_age: 3600
      - name: rate-limiting
        config:
          minute: ${service.rate_limit_minute}
          hour: ${service.rate_limit_hour}
          policy: local
      - name: request-transformer
        config:
          add:
            headers:
              - "X-Forwarded-By:Kong"
%{ endfor ~}

# Global plugins
plugins:
  - name: prometheus
    config:
      per_consumer: true
  - name: zipkin
    config:
      http_endpoint: "http://zipkin:9411/api/v2/spans"
      sample_ratio: 0.1
