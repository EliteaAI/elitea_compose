resource "local_file" "docker_compose" {
  content = templatefile(
    "${path.module}/tftemplates/docker_compose/docker-compose.yml.tpl",
    {
      PG_VECTOR_VER               = var.PG_VECTOR_VER
      PYLON_VER                   = var.PYLON_VER
      TOOLS_ENABLED               = var.TOOLS_ENABLED
      PYLON_REG                   = local.PYLON_REG_LOCAL
      HTTP_HOST_PORT              = var.HTTP_HOST_PORT
      HTTPS_HOST_PORT             = var.HTTPS_HOST_PORT
      SELF_HTTPS_ENABLED          = var.SELF_HTTPS
      ELITEA_REMOTE_REPO          = var.ELITEA_REMOTE_REPO
      PROXY_ENABLED               = var.PROXY_ENABLED
      ELITEA_RELEASE              = var.ELITEA_RELEASE
      EXTERNAL_PGSQL_SVC          = var.EXTERNAL_PGSQL_SVC_ENABLED
      EXTERNAL_REDIS_SVC          = var.EXTERNAL_REDIS_SVC_ENABLED
      CA_ENABLED                  = var.CA_ENABLED
      INTERNAL_OTPL_ENABLED       = var.INTERNAL_OTPL_ENABLED
      IMAGEGEN_PLUGIN_ENABLED     = var.IMAGEGEN_PLUGIN_ENABLED
      DEEPWIKI_PLUGIN_ENABLED     = var.DEEPWIKI_PLUGIN_ENABLED
      INVENTORY_PLUGIN_ENABLED    = var.INVENTORY_PLUGIN_ENABLED
      PG_CUSTOM_CONFIG_ENABLED    = var.PG_CUSTOM_CONFIG_ENABLED
      GRAFANA_MCP_ENABLED         = var.GRAFANA_MCP_ENABLED
      GRAFANA_MCP_TRANSPORT       = var.GRAFANA_MCP_TRANSPORT
      GRAFANA_MCP_ADDRESS         = var.GRAFANA_MCP_ADDRESS
      GRAFANA_MCP_ENDPOINT_PATH   = var.GRAFANA_MCP_ENDPOINT_PATH
      GRAFANA_MCP_ALLOWED_HOSTS   = var.GRAFANA_MCP_ALLOWED_HOSTS
      GRAFANA_MCP_LOG_LEVEL       = var.GRAFANA_MCP_LOG_LEVEL
      GRAFANA_MCP_ALLOWED_ORIGINS = var.GRAFANA_MCP_ALLOWED_ORIGINS
      GRAFANA_MCP_DISABLE_WRITE   = var.GRAFANA_MCP_DISABLE_WRITE
      ADO_MCP_ENABLED             = var.ADO_MCP_ENABLED
      ADO_MCP_IMAGE               = var.ADO_MCP_IMAGE
      ADO_MCP_ORGANIZATION        = var.ADO_MCP_ORGANIZATION
      ADO_MCP_AUTHENTICATION      = var.ADO_MCP_AUTHENTICATION
      ADO_MCP_TRANSPORT           = var.ADO_MCP_TRANSPORT
      ADO_MCP_HOST                = var.ADO_MCP_HOST
      ADO_MCP_PORT                = var.ADO_MCP_PORT
      ADO_MCP_ALLOWED_HOSTS       = var.ADO_MCP_ALLOWED_HOSTS
      REDIS_VER                   = var.REDIS_VER
    }
  )
  filename = "../docker-compose.yml"
}
