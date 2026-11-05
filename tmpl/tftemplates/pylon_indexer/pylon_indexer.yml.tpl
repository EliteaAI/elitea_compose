---

# General server config

server:
  name: $${NAME}
  path: /
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
    %{ if ELITEA_REMOTE_REPO != "3" }extra_index_url: https://download.pytorch.org/whl/cpu%{ endif }
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

# Environment configuration

environment:
  ANONYMIZED_TELEMETRY: "False"
  TOKENIZERS_PARALLELISM: "false"
  HF_HOME: /data/cache
  NLTK_DATA: /data/cache/nltk
  TRANSFORMERS_CACHE: /data/cache/transformers
  TIKTOKEN_CACHE_DIR: /data/cache/tiktoken
  AZURE_DEVOPS_CACHE_DIR: /data/cache/ado
