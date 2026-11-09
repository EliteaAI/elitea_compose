resource "local_file" "override" {
  content = templatefile(
    "${path.module}/tftemplates//env_overrides/override.env.tpl",
    {
      APP_HOST          = var.APP_HOST
      ELITEA_RELEASE    = var.ELITEA_RELEASE
      ADMIN_PASSWORD    = var.ADMIN_PASSWORD
      APP_AUTH_SECRET   = var.APP_AUTH_SECRET != "" ? var.APP_AUTH_SECRET : random_id.rnd_auth_secret.b64_std
      APP_MAIN_SECRET   = var.APP_MAIN_SECRET != "" ? var.APP_MAIN_SECRET : random_id.rnd_main_secret.b64_std
      MASTER_KEY        = var.MASTER_KEY != "" ? var.MASTER_KEY : "${random_id.fernet_key.b64_url}="
      EVENT_HMAC_KEY    = var.EVENT_HMAC_KEY != "" ? var.EVENT_HMAC_KEY : random_id.event_hmac_key.b64_url
      RPC_HMAC_KEY      = var.RPC_HMAC_KEY != "" ? var.RPC_HMAC_KEY : random_id.rpc_hmac_key.b64_url
      EXPOSURE_HMAC_KEY = var.EXPOSURE_HMAC_KEY != "" ? var.EXPOSURE_HMAC_KEY : random_id.exposure_hmac_key.b64_url
      INDEXER_HMAC_KEY  = var.INDEXER_HMAC_KEY != "" ? var.INDEXER_HMAC_KEY : random_id.indexer_hmac_key.b64_url
      MESH_HMAC_KEY     = random_id.mesh_hmac_key.b64_url
      REDIS_PASSWORD    = var.REDIS_PASSWORD

      ELITEA_REMOTE_REPO = var.ELITEA_REMOTE_REPO
      PROXY_ENABLED      = var.PROXY_ENABLED
      PROXY_HTTP         = var.PROXY_ENABLED_HTTP
      PROXY_HTTPS        = var.PROXY_ENABLED_HTTPS
      PROXY_NO_PROXY     = var.PROXY_ENABLED_NO_PROXY
      GITHUB_AUTH        = var.GITHUB_AUTH
      GITHUB_USER        = var.GITHUB_USER
      GITHUB_TOKEN       = var.GITHUB_TOKEN
      REDIS_HOST         = var.REDIS_HOST
      PGSQL_HOST         = var.PGSQL_HOST
      REDIS_PORT         = var.REDIS_PORT
      PGSQL_PORT         = var.PGSQL_PORT
      PGSQL_USER         = var.PGSQL_USER
      PGSQL_DB           = var.PGSQL_DB
      PGSQL_PASSWORD     = var.PGSQL_PASSWORD
      REDIS_SSL          = var.REDIS_SSL
      LB_HTTPS_ENABLED   = var.LB_HTTPS
      SELF_HTTPS_ENABLED = var.SELF_HTTPS
      ALLOWED_DOMAINS    = var.ALLOWED_DOMAINS

      PLUGINS_INITIAL_PROJECT = var.PLUGINS_INITIAL_PROJECT
      AI_RUN_PLATFORM_VERIFY  = var.AI_RUN_PLATFORM_VERIFY
      AI_RUN_PLATFORM_TIMEOUT = var.AI_RUN_PLATFORM_TIMEOUT
      AI_RUN_PLATFORM_DELAY   = var.AI_RUN_PLATFORM_DELAY
    }
  )
  filename = "../envs/override.env"
}

resource "local_file" "imagegen_ovverride" {
  count = var.IMAGEGEN_PLUGIN_ENABLED ? 1 : 0
  content = templatefile(
    "${path.module}/tftemplates/env_overrides/imagegen.env.tpl",
    {
      SERVICE_LOCATION_URL    = var.SERVICE_LOCATION_URL
      PLUGINS_INITIAL_PROJECT = var.PLUGINS_INITIAL_PROJECT
      AI_RUN_PLATFORM_VERIFY  = var.AI_RUN_PLATFORM_VERIFY
      AI_RUN_PLATFORM_TIMEOUT = var.AI_RUN_PLATFORM_TIMEOUT
      AI_RUN_PLATFORM_DELAY   = var.AI_RUN_PLATFORM_DELAY
      PLUGINS_INITIAL_TOKEN   = var.PLUGINS_INITIAL_TOKEN
      ELITEA_RELEASE          = var.ELITEA_RELEASE
    }
  )
  filename = "../envs/imagegen.env"
}

resource "local_file" "deepwiki_override" {
  count = var.DEEPWIKI_PLUGIN_ENABLED ? 1 : 0
  content = templatefile(
    "${path.module}/tftemplates/env_overrides/deepwiki.env.tpl",
    {
      SERVICE_LOCATION_URL    = var.SERVICE_LOCATION_URL
      PLUGINS_INITIAL_PROJECT = var.PLUGINS_INITIAL_PROJECT
      AI_RUN_PLATFORM_VERIFY  = var.AI_RUN_PLATFORM_VERIFY
      AI_RUN_PLATFORM_TIMEOUT = var.AI_RUN_PLATFORM_TIMEOUT
      AI_RUN_PLATFORM_DELAY   = var.AI_RUN_PLATFORM_DELAY
      PLUGINS_INITIAL_TOKEN   = var.PLUGINS_INITIAL_TOKEN
      ELITEA_RELEASE          = var.ELITEA_RELEASE
    }
  )
  filename = "../envs/deepwiki.env"
}

resource "local_file" "inventory_override" {
  count = var.INVENTORY_PLUGIN_ENABLED ? 1 : 0
  content = templatefile(
    "${path.module}/tftemplates/env_overrides/inventory.env.tpl",
    {
      SERVICE_LOCATION_URL    = var.SERVICE_LOCATION_URL
      PLUGINS_INITIAL_PROJECT = var.PLUGINS_INITIAL_PROJECT
      AI_RUN_PLATFORM_VERIFY  = var.AI_RUN_PLATFORM_VERIFY
      AI_RUN_PLATFORM_TIMEOUT = var.AI_RUN_PLATFORM_TIMEOUT
      AI_RUN_PLATFORM_DELAY   = var.AI_RUN_PLATFORM_DELAY
      PLUGINS_INITIAL_TOKEN   = var.PLUGINS_INITIAL_TOKEN
      ELITEA_RELEASE          = var.ELITEA_RELEASE
    }
  )
  filename = "../envs/inventory.env"
}


resource "local_file" "grafana_mcp_override" {
  count = var.GRAFANA_MCP_ENABLED ? 1 : 0
  content = templatefile(
    "${path.module}/tftemplates/env_overrides/grafana_mcp.env.tpl",
    {
      GRAFANA_URL                   = var.GRAFANA_URL
      GRAFANA_SERVICE_ACCOUNT_TOKEN = var.GRAFANA_SERVICE_ACCOUNT_TOKEN
      GRAFANA_ORG_ID                = var.GRAFANA_ORG_ID
      GRAFANA_EXTRA_HEADERS         = var.GRAFANA_EXTRA_HEADERS
    }
  )
  filename        = "../envs/grafana_mcp.env"
  file_permission = "0600"
}

resource "local_file" "ado_mcp_override" {
  count = var.ADO_MCP_ENABLED ? 1 : 0
  content = templatefile(
    "${path.module}/tftemplates/env_overrides/ado_mcp.env.tpl",
    {
      ADO_MCP_PERSONAL_ACCESS_TOKEN     = var.ADO_MCP_PERSONAL_ACCESS_TOKEN
      ADO_MCP_LEGACY_API_KEY_ENABLED    = var.ADO_MCP_LEGACY_API_KEY_ENABLED
      ADO_MCP_API_KEY                   = var.ADO_MCP_API_KEY
      ADO_MCP_MULTIPLE_API_KEYS_ENABLED = var.ADO_MCP_MULTIPLE_API_KEYS_ENABLED
      ADO_MCP_API_KEYS                  = var.ADO_MCP_API_KEYS
    }
  )
  filename        = "../envs/ado_mcp.env"
  file_permission = "0600"

  lifecycle {
    precondition {
      condition     = var.ADO_MCP_LEGACY_API_KEY_ENABLED || var.ADO_MCP_MULTIPLE_API_KEYS_ENABLED
      error_message = "At least one Azure DevOps MCP API key mode must be enabled."
    }
    precondition {
      condition     = trimspace(var.ADO_MCP_ORGANIZATION) != ""
      error_message = "ADO_MCP_ORGANIZATION must be set when Azure DevOps MCP is enabled."
    }
    precondition {
      condition     = trimspace(var.ADO_MCP_PERSONAL_ACCESS_TOKEN) != ""
      error_message = "ADO_MCP_PERSONAL_ACCESS_TOKEN must be set when Azure DevOps MCP is enabled."
    }
    precondition {
      condition     = !var.ADO_MCP_LEGACY_API_KEY_ENABLED || trimspace(var.ADO_MCP_API_KEY) != ""
      error_message = "ADO_MCP_API_KEY must be set when the shared API key is enabled."
    }
    precondition {
      condition     = !var.ADO_MCP_MULTIPLE_API_KEYS_ENABLED || can(length(keys(jsondecode(var.ADO_MCP_API_KEYS))) > 0)
      error_message = "ADO_MCP_API_KEYS must be a non-empty JSON object when labeled API keys are enabled."
    }
  }
}
