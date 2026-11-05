---
enabled: ${TRACING_ENABLED}

service:
  name: pylon-auth
  environment: production

audit_trail:
  enabled: true
  mode: writer
  retention_days: 90
  audit_all_methods: false
  skip_paths:
    - "/health"
    - "/metrics"
    - "/favicon.ico"
    - "/static"
    - "/admin/app/"

exclude:
  endpoints:
    - "health.check"
    - "monitoring.ping"
  paths:
    - "/health"
    - "/metrics"
    - "/favicon.ico"
    - "/static"

headers:
  parent_id: "X-Parent-ID"
  span_id: "X-Span-ID"
  trace_id: "X-Trace-ID"

instrumentation:
  database: true
  http_client: true
  http_requests: true
  logging: true
  rpc_calls: true
  socket_io: true

sampling:
  enabled: false
  rate: 1.0

event_node:
  type: RedisEventNode
  host: $${REDIS_HOST}
  port: $${REDIS_PORT}
  password: $${REDIS_PASSWORD}
  event_queue: $${NAME_PREFIX}_indexer_${EVENT_RND}
  hmac_key: $${INDEXER_HMAC_KEY}
  hmac_digest: sha512
  callback_workers: null
  use_ssl: $${REDIS_SSL}
  mute_first_failed_connections: 10


otlp:
  enabled: %{ if INTERNAL_OTPL_ENABLED }true%{else}false%{ endif }
  endpoint: %{ if INTERNAL_OTPL_ENABLED }http://pylon_otpl:4317%{ endif }
  http_endpoint: %{ if INTERNAL_OTPL_ENABLED }http://pylon_otpl:4318%{ endif }
  insecure: true
