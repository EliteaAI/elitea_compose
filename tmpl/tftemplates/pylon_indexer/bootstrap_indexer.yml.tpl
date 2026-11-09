---
debug: false

%{ if MESH_ENABLED }
mesh:
  event_node:
    type: ZeroMQEventNode
    connect_sub: "tcp://pylon_auth:5010"
    connect_push: "tcp://pylon_auth:5011"
    topic: mesh
    hmac_key: $${MESH_HMAC_KEY}
    hmac_digest: sha512
    callback_workers: null
    mute_first_failed_connections: 10
    log_errors: true
%{ endif }

autocreate_dbs:
  enabled: ${AUTOCREATE_DB}
  db_url: postgresql://$${POSTGRES_USER}:$${POSTGRES_PASSWORD}@$${POSTGRES_HOST}:$${POSTGRES_PORT}/$${POSTGRES_DB}
  db_names: ["litellm", "agentstate"]


%{ if ELITEA_REMOTE_REPO == "1" }
# Standard repo
plugin_repo:
  - type: elitea_github
    release: $${ELITEA_RELEASE}
    add_source_data: false
    add_head_data: false
%{ if GITHUB_AUTH }
    license_user: $${GITHUB_USER}
    license_password: $${GITHUB_TOKEN}
%{ endif }
%{ else }
%{ if ELITEA_REMOTE_REPO == "2" }
# Internal repo
plugin_repo:
  - type: repo_depot
    repo_url: "http://elitea-internal-repo:8080/target"
    release: $${ELITEA_RELEASE}
    license_token: internal
%{ endif }
%{ endif }


preordered_plugins:
  - worker_core
  - sdk_plugin
  - indexer_worker
  - provider_worker
  - runtime_engine_litellm
  - tracing
