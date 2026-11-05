---
# General server config

server:
  name: pylon_imagegen
  path: /
  proxy:
    x_for: 1
    x_proto: 1
    x_host: 1
  host: "0.0.0.0"
  port: 8080
  health:
    healthz: true
    livez: true
    readyz: true

# Logging

log:
  level: info
%{ if PROXY_ENABLED || CA_ENABLED }
# SSL CAs
ssl:
  certs:
    - /cacerts/ca.crt
%{ endif }

# Pylon DB
pylon_db:
  engine_url: sqlite:////data/pylon.db

# Local paths to modules and config

modules:
  plugins:
    provider:
      type: folder
      path: /data/plugins

  requirements:
    mode: relaxed
    activation: bulk
    cache: /data/cache/pip
    %{ if PROXY_ENABLED }trusted_hosts: [ "elitea-internal-repo" ]%{ endif }
    provider:
      type: folder
      path: /data/requirements

  config:
    provider:
      type: folder
      path: /data/configs
%{ if ELITEA_REMOTE_REPO == "1" || ELITEA_REMOTE_REPO == "2" }
  preload:
    bootstrap:
      provider:
        type: git
        delete_git_dir: false
        depth: null
      source: https://github.com/EliteaAI/bootstrap.git
      branch: $${ELITEA_RELEASE}
%{ else }
  preload:
    bootstrap:
      provider:
        type: http_tar
      source: "http://elitea-internal-repo:8080/target/public/depot/${ELITEA_RELEASE}/plugins/bootstrap/source"
%{ endif }
