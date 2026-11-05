variable "PG_VECTOR_VER" {
  type        = string
  default     = "0.8.7-pg18-trixie"
  description = "PG vector version"
}

variable "REDIS_VER" {
  type        = string
  default     = "8.10.3-alpine"
  description = "Redis version"
}

variable "PYLON_VER" {
  type        = string
  default     = "1.2.28"
  description = "Pylon version"
}

variable "TOOLS_ENABLED" {
  type        = bool
  default     = false
  description = "Enable Pylon tools image"
}

variable "PYLON_REGISTRY" {
  type        = string
  default     = "ghcr.io/eliteaai/pylon"
  description = "Pylon registry"
}
variable "SELF_HTTPS" {
  type        = bool
  default     = false
  description = "Elitea  will serve https itself"
}

variable "LB_HTTPS" {
  type        = bool
  default     = false
  description = "External Load Balancer has HTTPS enabled"
}

variable "AWS_REDIS" {
  type        = bool
  default     = false
  description = "Using the same redis for different Eliteas instances"
}

variable "PROXY_ENABLED" {
  type        = bool
  default     = false
  description = "enabled internal proxy"
}

variable "HTTP_HOST_PORT" {
  type        = string
  default     = "80"
  description = "HTTP port"
}

variable "HTTPS_HOST_PORT" {
  type        = string
  default     = "443"
  description = "HTTPS port"
}

variable "APP_HOST" {
  type        = string
  default     = "172.1.1.3"
  description = "IP or dns of service"
}

variable "ELITEA_RELEASE" {
  type        = string
  default     = "2.0.7"
  description = "Alita release"
}

variable "ELITEA_REMOTE_REPO" {
  type        = string
  default     = "1"
  description = "Alita New remote repository"
}

# --- Sensitive credentials ---

# FIX SH-004: removed weak hardcoded default "admin"
variable "ADMIN_PASSWORD" {
  type        = string
  default     = ""
  description = "Admin password"
  sensitive   = true
}

variable "APP_AUTH_SECRET" {
  type        = string
  default     = ""
  description = "APPLICATION AUTH SECRET KEY"
  sensitive   = true
}

variable "APP_MAIN_SECRET" {
  type        = string
  default     = ""
  description = "APPLICATION MAIN SECRET  KEY"
  sensitive   = true
}

variable "REDIS_PASSWORD" {
  type        = string
  default     = ""
  description = "redis password"
  sensitive   = true
}

variable "MASTER_KEY" {
  type        = string
  default     = ""
  description = "SECRETS_MASTER_KEY"
  sensitive   = true
}

variable "EVENT_HMAC_KEY" {
  type        = string
  default     = ""
  description = "SECRETS_EVENT_HMAC_KEY"
  sensitive   = true
}

variable "RPC_HMAC_KEY" {
  type        = string
  default     = ""
  description = "SECRETS_RPC_HMAC_KEY"
  sensitive   = true
}

variable "EXPOSURE_HMAC_KEY" {
  type        = string
  default     = ""
  description = "SECRETS_EXPOSURE_HMAC_KEY"
  sensitive   = true
}

variable "INDEXER_HMAC_KEY" {
  type        = string
  default     = ""
  description = "SECRETS_INDEXER_HMAC_KEY"
  sensitive   = true
}

variable "PGSQL_PASSWORD" {
  type        = string
  default     = ""
  description = "PG Password"
  sensitive   = true
}

variable "OIDC_CLIENT_SECRET" {
  type      = string
  default   = ""
  sensitive = true
}

variable "SAML_SP_KEY" {
  type      = string
  default   = ""
  sensitive = true
}

variable "SAML_SP_CERT" {
  type      = string
  default   = ""
  sensitive = true
}

variable "SAML_IDP_CERT" {
  type      = string
  default   = ""
  sensitive = true
}

# --- Network / Proxy ---

variable "PROXY_ENABLED_HTTP" {
  type        = string
  default     = ""
  description = "Proxy HTTP"
}

variable "PROXY_ENABLED_HTTPS" {
  type        = string
  default     = ""
  description = "Proxy HTTPS"
}

variable "PROXY_ENABLED_NO_PROXY" {
  type        = string
  default     = ""
  description = "Proxy NO_PROXY"
}

variable "EXTERNAL_PGSQL_SVC_ENABLED" {
  type        = bool
  default     = false
  description = "Enabled or Disable using External PostgreSQL service"
}

variable "EXTERNAL_REDIS_SVC_ENABLED" {
  type        = bool
  default     = false
  description = "Enabled or Disable using External Redis service"
}

variable "EXTERNAL_SVC_ENABLED" {
  type        = bool
  default     = false
  description = "Enabled or Disable using External RDS/REDIS"
}

variable "PGSQL_HOST" {
  type        = string
  default     = "postgres"
  description = ""
}

variable "PGSQL_DB" {
  type        = string
  default     = "db"
  description = ""
}

variable "PGSQL_USER" {
  type        = string
  default     = "postgres_user"
  description = ""
}

variable "REDIS_HOST" {
  type        = string
  default     = "redis"
  description = ""
}

variable "PGSQL_PORT" {
  type        = string
  default     = "5432"
  description = ""
}

variable "REDIS_PORT" {
  type        = string
  default     = "6379"
  description = ""
}

variable "REDIS_SSL" {
  type        = bool
  default     = false
  description = ""
}

variable "SSO_MODE" {
  type        = string
  description = "sso mode: form | saml | oidc"
  default     = "form"
}

variable "OIDC_AUTHORIZATION_ENDPOINT" {
  type    = string
  default = ""
}

variable "OIDC_CLIENT_ID" {
  type    = string
  default = ""
}

variable "OIDC_END_SESSION_ENDPOINT" {
  type    = string
  default = ""
}

variable "OIDC_METADATA_ENDPOINT" {
  type    = string
  default = ""
}

variable "OIDC_TOKEN_ENDPOINT" {
  type    = string
  default = ""
}

variable "OIDC_URL_MODE" {
  type    = string
  default = "external"
}

variable "OIDC_USERINFO_ENDPOINT" {
  type    = string
  default = ""
}

variable "SAML_AUTHN_DESTINATION" {
  type    = string
  default = ""
}

variable "SAML_LOGOUT_DESTINATION" {
  type    = string
  default = ""
}

variable "SAML_ISSUER" {
  type    = string
  default = ""
}

variable "SAML_IDP_METADATA" {
  type    = string
  default = ""
}

variable "ALLOWED_DOMAINS" {
  type        = string
  description = "String with allowed domains separated by comma"
  default     = "centry.user"
}

variable "CA_ENABLED" {
  type        = bool
  default     = false
  description = "enabled external ca"
}

variable "SSO_EXPIRATION_OVERRIDE" {
  type    = number
  default = 86400
}

variable "MESH_ENABLED" {
  type        = bool
  default     = false
  description = "enabled service mesh"
}

variable "TRACING_ENABLED" {
  type        = bool
  default     = false
  description = "enabled tracing"
}

variable "INTERNAL_OTPL_ENABLED" {
  type        = bool
  default     = false
  description = "enable OTLP export to an OpenTelemetry collector (otel-collector:4317/4318)"
}

variable "PG_CLOUD" {
  type        = bool
  default     = false
  description = "enabled Azure PostgreSQL cloud"
}

variable "AUTOCREATE_DB" {
  type        = bool
  default     = true
  description = "Automatically create the database"
}

#--- Plugins ---#

variable "IMAGEGEN_PLUGIN_ENABLED" {
  type        = bool
  default     = false
  description = "Enable image generation for plugins"
}

variable "DEEPWIKI_PLUGIN_ENABLED" {
  type        = bool
  default     = false
  description = "Enable DeepWiki plugin"
}

variable "INVENTORY_PLUGIN_ENABLED" {
  type        = bool
  default     = false
  description = "Enable Inventory plugin"
}

variable "PLUGINS_INITIAL_PROJECT" {
  type        = string
  default     = "1"
  description = "Initial project for plugins"
}

variable "PLUGINS_INITIAL_TOKEN" {
  type        = string
  default     = ""
  description = "Initial token for plugins"
}

variable "SERVICE_LOCATION_URL" {
  type        = string
  default     = "http://pylon_xxx:8000"
  description = "The URL where the service is located, used for plugins to call back to the main service"
}

variable "AI_RUN_PLATFORM_VERIFY" {
  type        = bool
  default     = false
  description = "Verify AI run platform"
}

variable "AI_RUN_PLATFORM_TIMEOUT" {
  type        = number
  default     = 120
  description = "Timeout for AI run platform"
}

variable "AI_RUN_PLATFORM_DELAY" {
  type        = number
  default     = 15
  description = "Delay for AI run platform"
}

variable "AI_RUN_PLATFORM_URL" {
  type        = string
  default     = "http://pylon_main:8000"
  description = "The URL where the AI run platform is located"
}

#--- PostgreSQL custom config ---#

variable "PG_CUSTOM_CONFIG_ENABLED" {
  type        = bool
  default     = false
  description = "Render and mount a custom postgresql.conf and pg_hba.conf into the postgres container"
}

variable "PG_MAX_CONNECTIONS" {
  type        = number
  default     = 60
  description = "PostgreSQL max_connections"
}

variable "PG_SHARED_BUFFERS" {
  type        = string
  default     = "4GB"
  description = "PostgreSQL shared_buffers"
}

variable "PG_EFFECTIVE_CACHE_SIZE" {
  type        = string
  default     = "12GB"
  description = "PostgreSQL effective_cache_size"
}

variable "PG_MAINTENANCE_WORK_MEM" {
  type        = string
  default     = "1GB"
  description = "PostgreSQL maintenance_work_mem"
}

variable "PG_CHECKPOINT_COMPLETION_TARGET" {
  type        = string
  default     = "0.9"
  description = "PostgreSQL checkpoint_completion_target"
}

variable "PG_WAL_BUFFERS" {
  type        = string
  default     = "16MB"
  description = "PostgreSQL wal_buffers"
}

variable "PG_DEFAULT_STATISTICS_TARGET" {
  type        = number
  default     = 100
  description = "PostgreSQL default_statistics_target"
}

variable "PG_RANDOM_PAGE_COST" {
  type        = string
  default     = "1.1"
  description = "PostgreSQL random_page_cost"
}

variable "PG_EFFECTIVE_IO_CONCURRENCY" {
  type        = number
  default     = 200
  description = "PostgreSQL effective_io_concurrency"
}

variable "PG_WORK_MEM" {
  type        = string
  default     = "16MB"
  description = "PostgreSQL work_mem"
}

variable "PG_HUGE_PAGES" {
  type        = string
  default     = "try"
  description = "PostgreSQL huge_pages (off | on | try)"
}

variable "PG_JIT" {
  type        = string
  default     = "off"
  description = "PostgreSQL jit (on | off)"
}

variable "PG_WAL_COMPRESSION" {
  type        = string
  default     = "lz4"
  description = "PostgreSQL wal_compression"
}

variable "PG_IO_METHOD" {
  type        = string
  default     = "sync"
  description = "PostgreSQL io_method (sync | worker | io_uring). Default is sync for container compatibility; set to io_uring only on kernels where it is explicitly permitted for unprivileged processes"
}

variable "PG_MIN_WAL_SIZE" {
  type        = string
  default     = "1GB"
  description = "PostgreSQL min_wal_size"
}

variable "PG_MAX_WAL_SIZE" {
  type        = string
  default     = "4GB"
  description = "PostgreSQL max_wal_size"
}

variable "PG_MAX_WORKER_PROCESSES" {
  type        = number
  default     = 4
  description = "PostgreSQL max_worker_processes"
}

variable "PG_MAX_PARALLEL_WORKERS_PER_GATHER" {
  type        = number
  default     = 2
  description = "PostgreSQL max_parallel_workers_per_gather"
}

variable "PG_MAX_PARALLEL_WORKERS" {
  type        = number
  default     = 4
  description = "PostgreSQL max_parallel_workers"
}

variable "PG_MAX_PARALLEL_MAINTENANCE_WORKERS" {
  type        = number
  default     = 2
  description = "PostgreSQL max_parallel_maintenance_workers"
}

variable "PG_WAL_LEVEL" {
  type        = string
  default     = "replica"
  description = "PostgreSQL wal_level (minimal | replica | logical)"
}

variable "PG_SYNCHRONOUS_COMMIT" {
  type        = string
  default     = "on"
  description = "PostgreSQL synchronous_commit"
}

variable "PG_LOG_MIN_DURATION_STATEMENT" {
  type        = number
  default     = 500
  description = "PostgreSQL log_min_duration_statement in ms (-1 to disable)"
}

variable "PG_LOG_CONNECTIONS" {
  type        = string
  default     = "off"
  description = "PostgreSQL log_connections (on | off)"
}

variable "PG_LOG_DISCONNECTIONS" {
  type        = string
  default     = "off"
  description = "PostgreSQL log_disconnections (on | off)"
}

variable "PG_LOG_LINE_PREFIX" {
  type        = string
  default     = "%t [%p]: [%l-1] %h %u %d "
  description = "PostgreSQL log_line_prefix"
}


#---MCP---#

variable "GRAFANA_MCP_ENABLED" {
  type        = bool
  default     = false
  description = "MCP enabled"
}

variable "GRAFANA_MCP_TRANSPORT" {
  type        = string
  default     = "streamable-http"
  description = "MCP transport protocol"
}

variable "GRAFANA_MCP_ADDRESS" {
  type        = string
  default     = ":8000"
  description = "MCP address"
}

variable "GRAFANA_MCP_ENDPOINT_PATH" {
  type        = string
  default     = "/mcp"
  description = "MCP endpoint path"
}

variable "GRAFANA_MCP_ALLOWED_HOSTS" {
  type        = string
  default     = "*"
  description = "MCP allowed hosts"
}

variable "GRAFANA_MCP_LOG_LEVEL" {
  type        = string
  default     = "info"
  description = "MCP log level"
}

variable "GRAFANA_MCP_ALLOWED_ORIGINS" {
  type        = string
  default     = ""
  description = "MCP allowed origins"
}

variable "GRAFANA_MCP_DISABLE_WRITE" {
  type        = bool
  default     = true
  description = "MCP disable write"
}

variable "GRAFANA_URL" {
  type        = string
  default     = ""
  description = "Grafana instance URL"
}

variable "GRAFANA_SERVICE_ACCOUNT_TOKEN" {
  type        = string
  default     = ""
  description = "Grafana token"
  sensitive   = true
}

variable "GRAFANA_ORG_ID" {
  type        = string
  default     = "1"
  description = "Grafana organization ID"
}

variable "GRAFANA_EXTRA_HEADERS" {
  type        = string
  default     = "{}"
  description = "Additional Grafana API headers as JSON"
}

variable "ADO_MCP_ENABLED" {
  type        = bool
  default     = false
  description = "Enable the Azure DevOps MCP server"
}

variable "ADO_MCP_IMAGE" {
  type        = string
  default     = "europe-west12-docker.pkg.dev/hl2-epm-elps-t1iylu/elitea-devops/ado-mcp:v2.9.0-elitea.5"
  description = "Azure DevOps MCP container image"
}

variable "ADO_MCP_ORGANIZATION" {
  type        = string
  default     = ""
  description = "Azure DevOps organization name"
}

variable "ADO_MCP_AUTHENTICATION" {
  type        = string
  default     = "pat"
  description = "Azure DevOps MCP authentication method"
}

variable "ADO_MCP_TRANSPORT" {
  type        = string
  default     = "http"
  description = "Azure DevOps MCP transport protocol"
}

variable "ADO_MCP_HOST" {
  type        = string
  default     = "0.0.0.0"
  description = "Azure DevOps MCP listen address"
}

variable "ADO_MCP_PORT" {
  type        = number
  default     = 3000
  description = "Azure DevOps MCP listen port"

  validation {
    condition     = var.ADO_MCP_PORT >= 1 && var.ADO_MCP_PORT <= 65535
    error_message = "ADO_MCP_PORT must be between 1 and 65535."
  }
}

variable "ADO_MCP_ALLOWED_HOSTS" {
  type        = string
  default     = "ado-mcp,localhost,127.0.0.1"
  description = "Comma-separated Azure DevOps MCP allowed hosts"
}

variable "ADO_MCP_PERSONAL_ACCESS_TOKEN" {
  type        = string
  default     = ""
  description = "Base64 encoding of :<Azure DevOps PAT>"
  sensitive   = true
}

variable "ADO_MCP_LEGACY_API_KEY_ENABLED" {
  type        = bool
  default     = true
  description = "Enable the shared inbound MCP API key"
}

variable "ADO_MCP_API_KEY" {
  type        = string
  default     = ""
  description = "Shared inbound MCP API key"
  sensitive   = true
}

variable "ADO_MCP_MULTIPLE_API_KEYS_ENABLED" {
  type        = bool
  default     = false
  description = "Enable labeled inbound MCP API keys"
}

variable "ADO_MCP_API_KEYS" {
  type        = string
  default     = "{}"
  description = "JSON object mapping audit IDs to inbound MCP API keys"
  sensitive   = true
}
