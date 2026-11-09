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
  - auth_core
  - auth_init
  - auth_mappers
  - auth_form
  - auth_oidc
  - auth_saml
  - auth_idp_rpc
  - tracing
