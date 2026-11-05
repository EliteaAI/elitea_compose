---

services:
  %{~ if !EXTERNAL_REDIS_SVC ~}
  redis:
    image: redis:${REDIS_VER}
    container_name: redis
    user: "999:1000"
    group_add:
      - "1000"
    command: >
      sh -c "redis-server --requirepass \"$$REDIS_PASSWORD\" --save 60 1 --dir /data/ --dbfilename dump.rdb --protected-mode yes --tcp-keepalive 300 --appendonly yes --maxmemory 512mb -- maxmemory-policy allkeys-lru"
    restart: unless-stopped
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    tmpfs:
      - /tmp
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    healthcheck:
      test: ["CMD-SHELL", "redis-cli -a \"$$REDIS_PASSWORD\" PING | grep -q PONG"]
      interval: 10s
      timeout: 3s
      retries: 10
    env_file:
      - ./envs/override.env
    volumes:
      - redis_data:/data
    networks:
      - elitea_net
  %{~ endif ~}

  %{~ if !EXTERNAL_PGSQL_SVC ~}
  postgres:
    image: pgvector/pgvector:${PG_VECTOR_VER}
    container_name: postgres
    shm_size: "4g"
    restart: unless-stopped
    read_only: true
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp
      - /var/run/postgresql
      - /run/postgresql
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \"$$POSTGRES_USER\" -d \"$$POSTGRES_DB\" -h 127.0.0.1 -p 5432"]
      interval: 10s
      timeout: 5s
      retries: 20
    env_file:
      - ./envs/override.env
    environment:
      - PGDATA=/data/pgdata
    command: ["postgres", "-c", "hba_file=/etc/postgresql/pg_hba.conf" %{~ if PG_CUSTOM_CONFIG_ENABLED ~},"-c", "config_file=/etc/postgresql/postgresql.conf"%{~ endif ~}]
    volumes:
      - postgres_data:/data
      %{~ if PG_CUSTOM_CONFIG_ENABLED ~}
      - ./pgsql_conf/postgresql.conf:/etc/postgresql/postgresql.conf:ro
      %{~ endif ~}
      - ./pgsql_conf/pg_hba.conf:/etc/postgresql/pg_hba.conf:ro
    networks:
      - elitea_net

  db-init-vector:
    image: pgvector/pgvector:${PG_VECTOR_VER}
    container_name: db-init-vector
    restart: "no"
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    depends_on:
      postgres:
        condition: service_healthy
    env_file:
      - ./envs/override.env
    networks:
      - elitea_net
    command: ["bash","-lc","until pg_isready -h postgres -p 5432 -U \"$$POSTGRES_USER\" -d \"$$POSTGRES_DB\"; do sleep 1; done; PGPASSWORD=\"$$POSTGRES_PASSWORD\" psql -v ON_ERROR_STOP=1 -h postgres -p 5432 -U \"$$POSTGRES_USER\" -d \"$$POSTGRES_DB\" -c \"CREATE EXTENSION IF NOT EXISTS vector;\""]
  %{~ endif ~}

  pylon_auth:
    image: ${PYLON_REG}:${PYLON_VER}
    restart: unless-stopped
    container_name: pylon_auth
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - DAC_OVERRIDE  # root in container must write /data regardless of host owner uid
    tmpfs:
      - /tmp:size=2g,mode=1777
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/override.env
    environment:
      - NAME=pylon-auth
      - PYLON_WEB_RUNTIME=gevent
      - PYLON_CONFIG_SEED=file:/data/pylon.yml
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/healthz", "-o", "/dev/null"]
      interval: 30s
      timeout: 10s
      retries: 5
    volumes:
      - ./pylon_auth:/data
      %{ if PROXY_ENABLED || CA_ENABLED }- ./cacerts:/cacerts:ro%{ endif }
    %{~ if ELITEA_REMOTE_REPO == "3" || !EXTERNAL_PGSQL_SVC || !EXTERNAL_REDIS_SVC ~}
    depends_on:
    %{~ endif ~}
    %{~ if ELITEA_REMOTE_REPO == "3" ~}
      elitea-internal-repo:
        condition: service_healthy
    %{~ endif ~}
    %{~if !EXTERNAL_REDIS_SVC ~}
      redis:
        condition: service_healthy
    %{~ endif ~}
    %{~if !EXTERNAL_PGSQL_SVC ~}
      postgres:
        condition: service_healthy
      db-init-vector:
        condition: service_completed_successfully
    %{~ endif ~}

    networks:
      - elitea_net

  pylon_main:
    image: ${PYLON_REG}:${PYLON_VER}${TOOLS_ENABLED ? "-tools" : ""}
    container_name: pylon_main
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - DAC_OVERRIDE  # root in container must write /data regardless of host owner uid
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/override.env
    healthcheck:
      %{~ if SELF_HTTPS_ENABLED ~}
      test: ["CMD", "curl", "-fk", "https://localhost:8443/healthz", "-o", "/dev/null"]
      %{~ else ~}
      test: ["CMD", "curl", "-f", "http://localhost:8080/healthz", "-o", "/dev/null"]
      %{~ endif ~}
      interval: 30s
      timeout: 10s
      retries: 5
    environment:
      - NAME=pylon-main
      - PYLON_WEB_RUNTIME=gevent
      - PYLON_CONFIG_SEED=file:/data/pylon.yml
    volumes:
${join("\n", concat(
  ["      - pylon_indexer_main:/tmp", "      - ./pylon_main:/data"],
  (PROXY_ENABLED || SELF_HTTPS_ENABLED || CA_ENABLED) ? ["      - ./cacerts:/cacerts:ro"] : [],
  SELF_HTTPS_ENABLED ? ["      - ./tlscerts:/ssl:ro"] : []
))}
    ports:
${SELF_HTTPS_ENABLED ? format("      - %s:8443", HTTPS_HOST_PORT) : format("      - %s:8080", HTTP_HOST_PORT)}
    depends_on:
      pylon_auth:
        condition: service_healthy
      %{~ if ELITEA_REMOTE_REPO == "3" ~}
      elitea-internal-repo:
        condition: service_healthy
      %{~ endif ~}
    %{~ if !EXTERNAL_REDIS_SVC ~}
      redis:
        condition: service_healthy
    %{~ endif ~}
    %{~ if !EXTERNAL_PGSQL_SVC ~}
      postgres:
        condition: service_healthy
      db-init-vector:
        condition: service_completed_successfully
    %{~ endif ~}
    networks:
      - elitea_net

  pylon_indexer:
    image: ${PYLON_REG}:${PYLON_VER}${TOOLS_ENABLED ? "-tools" : ""}
    container_name: pylon_indexer
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - DAC_OVERRIDE  # root in container must write /data regardless of host owner uid
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/override.env
    environment:
      - NAME=pylon-indexer
      - PYLON_WEB_RUNTIME=waitress
      - PYLON_CONFIG_SEED=file:/data/pylon.yml
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/healthz", "-o", "/dev/null"]
      interval: 30s
      timeout: 10s
      retries: 5
    volumes:
      - pylon_indexer_tmp:/tmp
      - ./pylon_indexer:/data
      %{ if PROXY_ENABLED || CA_ENABLED }- ./cacerts:/cacerts:ro%{ endif }
    depends_on:
      pylon_auth:
        condition: service_healthy
      %{~ if ELITEA_REMOTE_REPO == "3" ~}
      elitea-internal-repo:
        condition: service_healthy
      %{~ endif ~}
    %{~ if !EXTERNAL_REDIS_SVC ~}
      redis:
        condition: service_healthy
    %{~ endif ~}
    %{~ if !EXTERNAL_PGSQL_SVC ~}
      postgres:
        condition: service_healthy
      db-init-vector:
        condition: service_completed_successfully
    %{~ endif ~}
    networks:
      - elitea_net

  %{~ if IMAGEGEN_PLUGIN_ENABLED ~}
  pylon_imagegen:
    image: ${PYLON_REG}:${PYLON_VER}
    container_name: pylon_imagegen
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - DAC_OVERRIDE  # root in container must write /data regardless of host owner uid
    tmpfs:
      - /tmp
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/imagegen.env
    ports:
      - 8080
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/healthz", "-o", "/dev/null"]
      interval: 30s
      timeout: 10s
      retries: 5
    volumes:
      - ./pylon_imagegen:/data
      %{ if PROXY_ENABLED || CA_ENABLED }- ./cacerts:/cacerts:ro%{ endif }

    depends_on:
      pylon_main:
        condition: service_healthy
      %{~ if ELITEA_REMOTE_REPO == "3" ~}
      elitea-internal-repo:
        condition: service_healthy
      %{~ endif ~}
    networks:
      - elitea_net
    %{~ endif ~}

  %{~ if DEEPWIKI_PLUGIN_ENABLED ~}
  pylon_deepwiki:
    image: ${PYLON_REG}:${PYLON_VER}
    container_name: pylon_deepwiki
    restart: unless-stopped
    user: "33:33"
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - DAC_OVERRIDE  # root in container must write /data regardless of host owner uid
    tmpfs:
      - /tmp
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/deepwiki.env
    ports:
      - 8080
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/slots", "-o", "/dev/null"]
      interval: 30s
      timeout: 10s
      retries: 40
    volumes:
      - ./pylon_deepwiki:/data
      %{ if PROXY_ENABLED || CA_ENABLED }- ./cacerts:/cacerts:ro%{ endif }

    depends_on:
      pylon_main:
        condition: service_healthy
      %{~ if ELITEA_REMOTE_REPO == "3" ~}
      elitea-internal-repo:
        condition: service_healthy
      %{~ endif ~}
    networks:
      - elitea_net
  %{~ endif ~}

  %{~ if INVENTORY_PLUGIN_ENABLED ~}
  pylon_inventory:
    image: ${PYLON_REG}:${PYLON_VER}
    container_name: pylon_inventory
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - DAC_OVERRIDE  # root in container must write /data regardless of host owner uid
    tmpfs:
      - /tmp
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/inventory.env
    ports:
      - 8080
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health", "-o", "/dev/null"]
      interval: 30s
      timeout: 10s
      retries: 40
    volumes:
      - ./pylon_inventory:/data
      %{ if PROXY_ENABLED || CA_ENABLED }- ./cacerts:/cacerts:ro%{ endif }

    depends_on:
      pylon_main:
        condition: service_healthy
      %{~ if ELITEA_REMOTE_REPO == "3" ~}
      elitea-internal-repo:
        condition: service_healthy
      %{~ endif ~}
    networks:
      - elitea_net
  %{~ endif ~}
  %{~ if INTERNAL_OTPL_ENABLED ~}
  pylon_otpl:
    image: otel/opentelemetry-collector-contrib:0.140.0
    restart: unless-stopped
    container_name: pylon_otpl
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    volumes:
      - ./pylon_otpl:/data
    networks:
      - elitea_net
  %{~ endif ~}
  %{~ if ELITEA_REMOTE_REPO == "3" ~}
  elitea-internal-repo:
    image: "getcarrier/pylon:${PYLON_VER}-repo-${ELITEA_RELEASE}"
    container_name: elitea-internal-repo
    hostname: elitea-internal-repo
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/target/public/depot/${ELITEA_RELEASE}/plugins/bootstrap/source", "-o", "/dev/null"]
      interval: 30s
      timeout: 10s
      retries: 5
    networks:
      - elitea_net
  %{~ endif ~}
  %{~ if GRAFANA_MCP_ENABLED ~}
  grafana-mcp:
    image: "ghcr.io/eliteaai/grafana-mcp:1.0.0"
    container_name: grafana-mcp
    hostname: grafana-mcp
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/grafana_mcp.env
    entrypoint:
      - /app/mcp-grafana
    command:
      - --transport
      - "${GRAFANA_MCP_TRANSPORT}"
      - --address
      - "${GRAFANA_MCP_ADDRESS}"
      - --endpoint-path
      - "${GRAFANA_MCP_ENDPOINT_PATH}"
      - --allowed-hosts
      - "${GRAFANA_MCP_ALLOWED_HOSTS}"
      - --log-level
      - "${GRAFANA_MCP_LOG_LEVEL}"
      - --allowed-origins
      - "${GRAFANA_MCP_ALLOWED_ORIGINS}"
%{ if GRAFANA_MCP_DISABLE_WRITE ~}
      - --disable-write
%{ endif ~}
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8000/healthz"]
      interval: 30s
      timeout: 10s
      retries: 5
    networks:
      - elitea_net
  %{~ endif ~}
  %{~ if ADO_MCP_ENABLED ~}
  ado-mcp:
    image: "${ADO_MCP_IMAGE}"
    container_name: ado-mcp
    hostname: ado-mcp
    restart: unless-stopped
    user: "1000:1000"
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    tmpfs:
      - /tmp
    logging:
      driver: "json-file"
      options:
        max-file: "5"
        max-size: "10m"
    env_file:
      - ./envs/ado_mcp.env
    environment:
      MCP_ALLOWED_HOSTS: "${ADO_MCP_ALLOWED_HOSTS}"
    command:
      - "${ADO_MCP_ORGANIZATION}"
      - --transport
      - "${ADO_MCP_TRANSPORT}"
      - --host
      - "${ADO_MCP_HOST}"
      - --port
      - "${ADO_MCP_PORT}"
      - --authentication
      - "${ADO_MCP_AUTHENTICATION}"
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get({hostname:'127.0.0.1',port:${ADO_MCP_PORT},path:'/healthz',headers:{Host:'ado-mcp'}},r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"]
      interval: 30s
      timeout: 10s
      retries: 5
    volumes:
      - ado_mcp_cache:/home/node
    networks:
      - elitea_net
  %{~ endif ~}

volumes:
  pylon_indexer_tmp:
  pylon_indexer_main:
%{ if !EXTERNAL_REDIS_SVC ~}
  redis_data:
%{ endif ~}
%{ if !EXTERNAL_PGSQL_SVC ~}
  postgres_data:
%{ endif ~}
%{ if ADO_MCP_ENABLED ~}
  ado_mcp_cache:
%{ endif ~}

networks:
  elitea_net:
    driver: bridge
    internal: false
