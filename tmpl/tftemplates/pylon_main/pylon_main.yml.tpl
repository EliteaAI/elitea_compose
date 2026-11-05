---
# General server config

server:
  name: $${NAME}
  path: /
  proxy:
    x_for: 1
    x_proto: 1
    x_host: 1
  host: "0.0.0.0"
  %{ if SELF_HTTPS_ENABLED }
  port: 8443
  kwargs:
    certfile: /cacerts/server.crt
    keyfile: /cacerts/server.key
  %{else}
  port: 8080
  %{ endif }
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

# Exposure
exposure:
  event_node:
    type: RedisEventNode
    host: $${REDIS_HOST}
    port: $${REDIS_PORT}
    password: $${REDIS_PASSWORD}
    event_queue: $${NAME_PREFIX}_exposure_events_${EVENT_RND}
    hmac_key: $${EXPOSURE_HMAC_KEY}
    hmac_digest: sha512
    callback_workers: null
    use_ssl: $${REDIS_SSL}
  handle:
    enabled: true
    prefixes:
      - /forward-auth

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

# Environment configuration

environment:
  NLTK_DATA: /data/cache/nltk
  TRANSFORMERS_CACHE: /data/cache/transformers
  TIKTOKEN_CACHE_DIR: /data/cache/tiktoken

# Persistent sessions

sessions:
  redis:
    host: $${REDIS_HOST}
    port: $${REDIS_PORT}
    password: $${REDIS_PASSWORD}
    use_ssl: $${REDIS_SSL}
  prefix: $${NAME_PREFIX}_main_session_

# Events queue

events:
  redis:
    host: $${REDIS_HOST}
    port: $${REDIS_PORT}
    password: $${REDIS_PASSWORD}
    use_ssl: $${REDIS_SSL}
    queue: $${NAME_PREFIX}_events_${EVENT_RND}
    hmac_key: $${EVENT_HMAC_KEY}
    hmac_digest: sha512
    callback_workers: null

# RPC

rpc:
  redis:
    host: $${REDIS_HOST}
    port: $${REDIS_PORT}
    password: $${REDIS_PASSWORD}
    use_ssl: $${REDIS_SSL}
    queue: $${NAME_PREFIX}_rpc_${EVENT_RND}
    hmac_key: $${RPC_HMAC_KEY}
    hmac_digest: sha512
    callback_workers: null
  id_prefix: $${NAME_PREFIX}_main_rpc_

# Settings for Flask application

application:
  SECRET_KEY: $${APPLICATION_MAIN_SECRET_KEY}
  SESSION_COOKIE_NAME: $${NAME_PREFIX}_main_session
  SESSION_COOKIE_DOMAIN: $${APP_HOST}
  SESSION_COOKIE_PATH: /
  SESSION_COOKIE_HTTPONLY: true
  SESSION_COOKIE_SECURE: $${COOKIES_SECURE}
  PERMANENT_SESSION_LIFETIME: 86400
  PREFERRED_URL_SCHEME: $${APP_PROTO}
