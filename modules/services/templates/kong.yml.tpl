# Kong Configuration Template
# This template loads services from individual YAML files in kong-services/

_format_version: "3.0"

services:
%{ for service in services ~}
  - name: ${service.name}
    url: ${service.url}
    routes:
%{ for route in service.routes ~}
      - name: ${route.name}
        paths:
%{ for path in route.paths ~}
          - ${path}
%{ endfor ~}
        methods:
%{ for method in route.methods ~}
          - ${method}
%{ endfor ~}
        strip_path: ${route.strip_path}
        preserve_host: ${route.preserve_host}
%{ endfor ~}
    plugins:
%{ for plugin in service.plugins ~}
      - name: ${plugin.name}
        config:
%{ for key, value in plugin.config ~}
%{ if can(tolist(value)) ~}
          ${key}:
%{ for item in value ~}
            - ${item}
%{ endfor ~}
%{ else if can(tomap(value)) ~}
          ${key}:
%{ for subkey, subvalue in value ~}
%{ if can(tolist(subvalue)) ~}
            ${subkey}:
%{ for item in subvalue ~}
              - ${item}
%{ endfor ~}
%{ else ~}
            ${subkey}: ${subvalue}
%{ endif ~}
%{ endfor ~}
%{ else ~}
          ${key}: ${value}
%{ endif ~}
%{ endfor ~}
%{ endfor ~}
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
