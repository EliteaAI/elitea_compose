.PHONY: help up up_minimal stop down restart initial_check prepare_ubuntu prepare_rocky get_tools init plan apply clean_tf clean_images clean_volumes clean_local_db clean_cache clean_start full_clean check_config

SHELL := /bin/bash
FREE_SPACE_THRESHOLD ?= 30
PG_VECTOR_VERSION ?= 0.8.7-pg18-trixie
REDIS_VER ?= 8.10.3-alpine
PYLON_VER ?= 1.2.28
TOOLS_ENABLED ?= false
HTTP_HOST_PORT ?= 80
HTTPS_HOST_PORT ?= 443
LB_HTTPS ?= false
SELF_HTTPS ?= false
PGSQL_HOST ?= postgres
PGSQL_PORT ?= 5432
REDIS_HOST ?= redis
REDIS_PORT ?= 6379
REDIS_SSL ?= false
PROXY_ENABLED ?= false
PROXY_ENABLED_HTTP ?=
PROXY_ENABLED_HTTPS ?=
PROXY_ENABLED_NO_PROXY ?=
EXTERNAL_PGSQL_SVC_ENABLED ?= false
EXTERNAL_REDIS_SVC_ENABLED ?= false
# SSO
SSO_ENABLED ?= false
SSO_MODE ?= form
OIDC_AUTHORIZATION_ENDPOINT ?= ""
OIDC_CLIENT_ID ?= ""
OIDC_CLIENT_SECRET ?= ""
OIDC_END_SESSION_ENDPOINT ?= ""
OIDC_METADATA_ENDPOINT ?= ""
OIDC_TOKEN_ENDPOINT ?= ""
OIDC_URL_MODE ?= external
OIDC_USERINFO_ENDPOINT ?= ""
SAML_AUTHN_DESTINATION ?= ""
SAML_LOGOUT_DESTINATION ?= ""
SAML_ISSUER ?= ""
SAML_SP_KEY ?= ""
SAML_SP_CERT ?= ""
SAML_IDP_METADATA ?= ""
SAML_IDP_CERT ?= ""
ALLOWED_DOMAINS ?= "centry.user"
CA_ENABLED ?= false
AWS_REDIS ?= false
PG_CLOUD ?= false
MESH_ENABLED ?= false
TRACING_ENABLED ?= false
INTERNAL_OTPL_ENABLED ?= false
IMAGEGEN_PLUGIN_ENABLED ?= false
DEEPWIKI_PLUGIN_ENABLED ?= false
INVENTORY_PLUGIN_ENABLED ?= false
PG_CUSTOM_CONFIG_ENABLED ?= false
GRAFANA_MCP_ENABLED ?= false
GRAFANA_MCP_TRANSPORT ?= "streamable-http"
GRAFANA_MCP_ADDRESS ?= ":8000"
GRAFANA_MCP_ENDPOINT_PATH ?= "/mcp"
GRAFANA_MCP_ALLOWED_HOSTS ?= "*"
GRAFANA_MCP_LOG_LEVEL ?= "info"
GRAFANA_MCP_ALLOWED_ORIGINS ?= ""
GRAFANA_MCP_DISABLE_WRITE ?= true
GRAFANA_URL ?=
GRAFANA_SERVICE_ACCOUNT_TOKEN ?=
GRAFANA_ORG_ID ?= "1"
GRAFANA_EXTRA_HEADERS ?= {}
ADO_MCP_ENABLED ?= false
ADO_MCP_IMAGE ?= europe-west12-docker.pkg.dev/hl2-epm-elps-t1iylu/elitea-devops/ado-mcp:v2.9.0-elitea.5
ADO_MCP_ORGANIZATION ?=
ADO_MCP_AUTHENTICATION ?= "pat"
ADO_MCP_TRANSPORT ?= "http"
ADO_MCP_HOST ?= "0.0.0.0"
ADO_MCP_PORT ?= 3000
ADO_MCP_ALLOWED_HOSTS ?= ado-mcp,localhost,127.0.0.1
ADO_MCP_PERSONAL_ACCESS_TOKEN ?=
ADO_MCP_LEGACY_API_KEY_ENABLED ?= true
ADO_MCP_API_KEY ?=
ADO_MCP_MULTIPLE_API_KEYS_ENABLED ?= false
ADO_MCP_API_KEYS ?= {}


LOCAL_BIN_PATH = $(HOME)/.local/bin
TERRAFORM_BIN = $(HOME)/.local/bin/terraform

# --- Terraform cross-platform URL (Linux/macOS × amd64/arm64) ---
TERRAFORM_VERSION ?= 1.16.5
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
# Normalize OS
TF_OS := $(if $(filter Linux,$(UNAME_S)),linux,$(if $(filter Darwin,$(UNAME_S)),darwin,unsupported))
# Normalize ARCH
TF_ARCH := $(if $(filter x86_64 amd64,$(UNAME_M)),amd64,$(if $(filter arm64 aarch64,$(UNAME_M)),arm64,unsupported))
# Final URL
TERRAFORM_URL = https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_$(TF_OS)_$(TF_ARCH).zip


APP_HOST ?= 172.1.1.1
# Remove paths that containers (root, cap DAC_OVERRIDE) may have created: try plain rm, else rm inside a throwaway container.
# No sudo needed, works for any host user. Uses the redis image (alpine) that the stack already pulled.
define RMR
rm -rf $(1) 2>/dev/null || docker run --rm -v "$(CURDIR)":/w -w /w --entrypoint rm redis:$(REDIS_VER) -rf $(1)
endef

ELITEA_RELEASE ?= 2.0.7
ELITEA_REMOTE_REPO ?= 1
ADMIN_PASSWORD ?= admin
APP_AUTH_SECRET ?=
APP_MAIN_SECRET ?=
MASTER_KEY ?=
EVENT_HMAC_KEY ?=
RPC_HMAC_KEY ?=
EXPOSURE_HMAC_KEY ?=
INDEXER_HMAC_KEY ?=
REDIS_PASSWORD ?= redis_admin_pwd
PGSQL_PASSWORD ?= pg_admin_pwd
PGSQL_USER ?= postgres_user
PGSQL_DB ?= db
PG_VERSION ?= 18
SSO_EXPIRATION_OVERRIDE ?= 86400

DOCKER_COMPOSE := docker compose

help: ## Show this help
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  up               - start service"
	@echo "  up_minimal       - start minimal working configuration"
	@echo "  stop             - stop containers"
	@echo "  down             - down docker compose"
	@echo "  restart          - recreate all containers"
	@echo "  restart_dp|restart_img|restart_inv - recreate deepwiki|imagegen|inventory"
	@echo "  logs             - show logs flow (all containers)"
	@echo "  logs_main|logs_auth|logs_indexer|logs_deepwiki|logs_inventory|logs_imagegen - show logs of one service"
	@echo "  check            - check section"
	@echo "  check_config     - validate override.env and docker-compose.yml"
	@echo "  bump_release     - change ELITEA_RELEASE version"
	@echo "  clean_images     - remove docker images only"
	@echo "  clean_volumes    - remove docker volumes only"
	@echo "  clean_local_db   - remove local pylon DBs"
	@echo "  clean_cache      - remove plugins, requirements and cache dirs"
	@echo "  clean_local_plugins - alias for clean_cache"
	@echo "  clean_local_cache   - alias for clean_cache"
	@echo "  clean_start      - remove local files (keep images/volumes)"
	@echo "  clean_full       - full remove sequence"
	@echo "  clean_tf         - remove terraform files"
	@echo "  init|plan|apply  - terraform workflow"
	@echo "  get_tools        - download terraform"
	@echo "  prepare_ubuntu   - host tuning, base packages, docker install"
	@echo "  prepare_rocky    - host tuning, base packages, docker install"

up: initial_check
	@echo "Starting docker compose..."
	@$(DOCKER_COMPOSE) -f docker-compose.yml up -d

up_minimal:
	@echo "Starting docker compose..."
	$(DOCKER_COMPOSE) -f docker-compose.yml up -d pylon_main pylon_auth

stop:
	@echo "Stopping container..."
	@$(DOCKER_COMPOSE) -f docker-compose.yml stop

down:
	@echo "Stopping docker compose and remove networks..."
	@$(DOCKER_COMPOSE) -f docker-compose.yml down

restart:
	@echo "Restarting docker compose..."
	@$(DOCKER_COMPOSE) -f docker-compose.yml up -d --force-recreate

initial_check:
	@echo "Run Checks..."
	@if [ -f .label ]; then \
	  echo "It's not a first run...skipping checks....."; \
	else \
	  echo "Proceed checks...."; \
	  FREE_GB=$$(df -k . | awk 'NR==2 { printf "%d", $$4/1024/1024 }'); \
	  if [ "$$FREE_GB" -lt "$(FREE_SPACE_THRESHOLD)" ]; then \
	    echo "Not enough free space: got $${FREE_GB}G (need >= $(FREE_SPACE_THRESHOLD)G)"; \
	    exit 1; \
	  else \
	    echo "Enough free space $${FREE_GB}G...Continue....."; \
	    touch .label; \
	  fi; \
	fi

prepare_ubuntu:
	@sudo rm -f /etc/apt/sources.list.d/docker*.list /etc/apt/sources.list.d/docker*.sources
	@echo "Installing base packages..."
	@sudo apt update
	@sudo apt install -y git unzip curl vim
	@echo "Installing Docker from official repo..."
	@sudo apt update
	@sudo apt install -y ca-certificates curl
	@sudo install -m 0755 -d /etc/apt/keyrings
	@sudo rm -f /etc/apt/sources.list.d/docker*.list /etc/apt/sources.list.d/docker*.sources
	@distro=$$(. /etc/os-release && case "$$ID" in ubuntu) echo ubuntu;; debian) echo debian;; *) case "$$ID_LIKE" in *ubuntu*) echo ubuntu;; *) echo debian;; esac;; esac); \
	if [ -f /etc/apt/keyrings/docker.gpg ]; then \
		keyring=/etc/apt/keyrings/docker.gpg; \
	else \
		sudo curl -fsSL https://download.docker.com/linux/$$distro/gpg -o /etc/apt/keyrings/docker.asc; \
		sudo chmod a+r /etc/apt/keyrings/docker.asc; \
		keyring=/etc/apt/keyrings/docker.asc; \
	fi; \
	suite=$$(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$$VERSION_CODENAME}"); \
	printf '%s\n' \
		'Types: deb' \
		"URIs: https://download.docker.com/linux/$$distro" \
		"Suites: $$suite" \
		'Components: stable' \
		"Signed-By: $$keyring" | sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null
	@sudo apt update
	@sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

prepare_rocky:
	@echo "Installing base packages..."
	@sudo dnf install -y git unzip curl vim
	@echo "Installing Docker from official repo..."
	@sudo rm -f /etc/yum.repos.d/docker-ce.repo
	@sudo dnf install -y dnf-plugins-core
	@sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	@sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin net-tools

get_tools:
	@echo "Download tools..."
	@if [ "$(TF_OS)" = "unsupported" ] || [ "$(TF_ARCH)" = "unsupported" ]; then \
		echo "Unsupported platform: $(UNAME_S) $(UNAME_M)"; exit 1; \
	fi; \
	if [ ! -d $(LOCAL_BIN_PATH) ]; then mkdir -p $(LOCAL_BIN_PATH); \
	fi; \
	if command -v wget >/dev/null 2>&1; then \
		wget -L $(TERRAFORM_URL) -O $(LOCAL_BIN_PATH)/terraform.zip; \
	elif command -v curl >/dev/null 2>&1; then \
	  curl -L -o $(LOCAL_BIN_PATH)/terraform.zip $(TERRAFORM_URL); \
	else \
	  echo "wget and curl not found"; exit 1; \
	fi; \
	if ! grep -q '$(LOCAL_BIN_PATH)' $(HOME)/.bashrc 2>/dev/null; then \
	  echo 'export PATH=$$PATH:$(LOCAL_BIN_PATH)' >> $(HOME)/.bashrc; \
	fi; \
	if [ -n "$$ZSH_NAME" ] && ! grep -q '$(LOCAL_BIN_PATH)' $(HOME)/.zshrc 2>/dev/null; then \
	  echo 'export PATH=$$PATH:$(LOCAL_BIN_PATH)' >> $(HOME)/.zshrc; \
	fi; \
	if command -v unzip >/dev/null 2>&1; then \
	  unzip -o $(LOCAL_BIN_PATH)/terraform.zip -d $(LOCAL_BIN_PATH)/; \
	  chmod +x $(LOCAL_BIN_PATH)/terraform; \
	  rm -f "$(LOCAL_BIN_PATH)/terraform.zip"; \
	else \
	  echo "Install unzip to extract Terraform archive..."; \
	fi

init:
	@echo "Init terraform providers"
	$(TERRAFORM_BIN) -chdir=./tmpl init -upgrade

plan:
	@echo "Plan rendering docker compose"
	@$(TERRAFORM_BIN) -chdir=./tmpl plan -var PYLON_VER=$(PYLON_VER) -var PG_VECTOR_VER=$(PG_VECTOR_VERSION) -var REDIS_VER=$(REDIS_VER) \
	        -var TOOLS_ENABLED=$(TOOLS_ENABLED) \
	        -var HTTP_HOST_PORT=$(HTTP_HOST_PORT) -var HTTPS_HOST_PORT=$(HTTPS_HOST_PORT) -var LB_HTTPS=$(LB_HTTPS) -var SELF_HTTPS=$(SELF_HTTPS) -var PROXY_ENABLED=$(PROXY_ENABLED) \
			-var PROXY_ENABLED_HTTP=$(PROXY_ENABLED_HTTP) -var PROXY_ENABLED_HTTPS=$(PROXY_ENABLED_HTTPS) -var PROXY_ENABLED_NO_PROXY=$(PROXY_ENABLED_NO_PROXY) \
	        -var ELITEA_REMOTE_REPO=$(ELITEA_REMOTE_REPO) \
	        -var ELITEA_RELEASE=$(ELITEA_RELEASE) -var ADMIN_PASSWORD=$(ADMIN_PASSWORD) \
	        -var APP_AUTH_SECRET=$(APP_AUTH_SECRET) -var APP_MAIN_SECRET=$(APP_MAIN_SECRET) \
	        -var MASTER_KEY=$(MASTER_KEY) -var EVENT_HMAC_KEY=$(EVENT_HMAC_KEY) -var RPC_HMAC_KEY=$(RPC_HMAC_KEY) \
		-var EXPOSURE_HMAC_KEY=$(EXPOSURE_HMAC_KEY) -var INDEXER_HMAC_KEY=$(INDEXER_HMAC_KEY) \
	        -var REDIS_PASSWORD=$(REDIS_PASSWORD) -var PGSQL_PASSWORD=$(PGSQL_PASSWORD) \
	        -var APP_HOST=$(APP_HOST) \
			-var PGSQL_HOST=$(PGSQL_HOST) -var REDIS_HOST=$(REDIS_HOST) -var PGSQL_PORT=$(PGSQL_PORT) -var REDIS_PORT=$(REDIS_PORT) -var REDIS_SSL=$(REDIS_SSL) \
			-var EXTERNAL_PGSQL_SVC_ENABLED=$(EXTERNAL_PGSQL_SVC_ENABLED) -var EXTERNAL_REDIS_SVC_ENABLED=$(EXTERNAL_REDIS_SVC_ENABLED) \
			-var SSO_MODE=$(SSO_MODE) -var OIDC_AUTHORIZATION_ENDPOINT=$(OIDC_AUTHORIZATION_ENDPOINT) \
			-var OIDC_CLIENT_ID=$(OIDC_CLIENT_ID) -var OIDC_CLIENT_SECRET=$(OIDC_CLIENT_SECRET) -var OIDC_END_SESSION_ENDPOINT=$(OIDC_END_SESSION_ENDPOINT) \
			-var OIDC_METADATA_ENDPOINT=$(OIDC_METADATA_ENDPOINT) -var OIDC_TOKEN_ENDPOINT=$(OIDC_TOKEN_ENDPOINT) -var OIDC_URL_MODE=$(OIDC_URL_MODE) \
			-var OIDC_USERINFO_ENDPOINT=$(OIDC_USERINFO_ENDPOINT) -var SAML_AUTHN_DESTINATION=$(SAML_AUTHN_DESTINATION) \
			-var SAML_LOGOUT_DESTINATION=$(SAML_LOGOUT_DESTINATION) -var SAML_ISSUER=$(SAML_ISSUER) -var SAML_SP_KEY=$(SAML_SP_KEY) \
			-var SAML_SP_CERT=$(SAML_SP_CERT) -var SAML_IDP_METADATA=$(SAML_IDP_METADATA) -var SAML_IDP_CERT=$(SAML_IDP_CERT) \
			-var ALLOWED_DOMAINS=$(ALLOWED_DOMAINS) -var CA_ENABLED=$(CA_ENABLED) -var PGSQL_USER=$(PGSQL_USER) -var PGSQL_DB=$(PGSQL_DB) -var AWS_REDIS=$(AWS_REDIS) \
			-var PG_CLOUD=$(PG_CLOUD) -var MESH_ENABLED=$(MESH_ENABLED) -var SSO_EXPIRATION_OVERRIDE=$(SSO_EXPIRATION_OVERRIDE) -var TRACING_ENABLED=$(TRACING_ENABLED) \
		 -var INTERNAL_OTPL_ENABLED=$(INTERNAL_OTPL_ENABLED) \
		-var IMAGEGEN_PLUGIN_ENABLED=$(IMAGEGEN_PLUGIN_ENABLED) -var DEEPWIKI_PLUGIN_ENABLED=$(DEEPWIKI_PLUGIN_ENABLED) -var INVENTORY_PLUGIN_ENABLED=$(INVENTORY_PLUGIN_ENABLED) -var PLUGINS_INITIAL_TOKEN=$(PLUGINS_INITIAL_TOKEN) -var PLUGINS_INITIAL_PROJECT=$(PLUGINS_INITIAL_PROJECT) \
		-var PG_CUSTOM_CONFIG_ENABLED=$(PG_CUSTOM_CONFIG_ENABLED) \
		-var GRAFANA_MCP_ENABLED=$(GRAFANA_MCP_ENABLED) -var GRAFANA_MCP_TRANSPORT=$(GRAFANA_MCP_TRANSPORT) -var GRAFANA_MCP_ADDRESS=$(GRAFANA_MCP_ADDRESS) \
		-var GRAFANA_MCP_ENDPOINT_PATH=$(GRAFANA_MCP_ENDPOINT_PATH) -var GRAFANA_MCP_ALLOWED_HOSTS=$(GRAFANA_MCP_ALLOWED_HOSTS) -var GRAFANA_MCP_LOG_LEVEL=$(GRAFANA_MCP_LOG_LEVEL) \
		-var GRAFANA_MCP_ALLOWED_ORIGINS=$(GRAFANA_MCP_ALLOWED_ORIGINS) -var GRAFANA_MCP_DISABLE_WRITE=$(GRAFANA_MCP_DISABLE_WRITE) \
		-var 'GRAFANA_URL=$(GRAFANA_URL)' -var 'GRAFANA_SERVICE_ACCOUNT_TOKEN=$(GRAFANA_SERVICE_ACCOUNT_TOKEN)' -var GRAFANA_ORG_ID=$(GRAFANA_ORG_ID) -var 'GRAFANA_EXTRA_HEADERS=$(GRAFANA_EXTRA_HEADERS)' \
		-var ADO_MCP_ENABLED=$(ADO_MCP_ENABLED) -var 'ADO_MCP_IMAGE=$(ADO_MCP_IMAGE)' -var 'ADO_MCP_ORGANIZATION=$(ADO_MCP_ORGANIZATION)' \
		-var ADO_MCP_AUTHENTICATION=$(ADO_MCP_AUTHENTICATION) -var ADO_MCP_TRANSPORT=$(ADO_MCP_TRANSPORT) -var ADO_MCP_HOST=$(ADO_MCP_HOST) -var ADO_MCP_PORT=$(ADO_MCP_PORT) \
		-var 'ADO_MCP_ALLOWED_HOSTS=$(ADO_MCP_ALLOWED_HOSTS)' -var 'ADO_MCP_PERSONAL_ACCESS_TOKEN=$(ADO_MCP_PERSONAL_ACCESS_TOKEN)' \
		-var ADO_MCP_LEGACY_API_KEY_ENABLED=$(ADO_MCP_LEGACY_API_KEY_ENABLED) -var 'ADO_MCP_API_KEY=$(ADO_MCP_API_KEY)' \
		-var ADO_MCP_MULTIPLE_API_KEYS_ENABLED=$(ADO_MCP_MULTIPLE_API_KEYS_ENABLED) -var 'ADO_MCP_API_KEYS=$(ADO_MCP_API_KEYS)'

apply:
	@echo "Rendering docker compose"
	@$(TERRAFORM_BIN) -chdir=./tmpl apply -auto-approve -var PYLON_VER=$(PYLON_VER) -var PG_VECTOR_VER=$(PG_VECTOR_VERSION) -var REDIS_VER=$(REDIS_VER) \
			-var TOOLS_ENABLED=$(TOOLS_ENABLED) \
	        -var HTTP_HOST_PORT=$(HTTP_HOST_PORT) -var HTTPS_HOST_PORT=$(HTTPS_HOST_PORT) -var LB_HTTPS=$(LB_HTTPS) -var SELF_HTTPS=$(SELF_HTTPS) -var PROXY_ENABLED=$(PROXY_ENABLED) \
			-var PROXY_ENABLED_HTTP=$(PROXY_ENABLED_HTTP) -var PROXY_ENABLED_HTTPS=$(PROXY_ENABLED_HTTPS) -var PROXY_ENABLED_NO_PROXY=$(PROXY_ENABLED_NO_PROXY) \
	        -var ELITEA_REMOTE_REPO=$(ELITEA_REMOTE_REPO) \
	        -var ELITEA_RELEASE=$(ELITEA_RELEASE) -var ADMIN_PASSWORD=$(ADMIN_PASSWORD) \
	        -var APP_AUTH_SECRET=$(APP_AUTH_SECRET) -var APP_MAIN_SECRET=$(APP_MAIN_SECRET) \
	        -var MASTER_KEY=$(MASTER_KEY) -var EVENT_HMAC_KEY=$(EVENT_HMAC_KEY) -var RPC_HMAC_KEY=$(RPC_HMAC_KEY) \
		-var EXPOSURE_HMAC_KEY=$(EXPOSURE_HMAC_KEY) -var INDEXER_HMAC_KEY=$(INDEXER_HMAC_KEY) \
	        -var REDIS_PASSWORD=$(REDIS_PASSWORD) -var PGSQL_PASSWORD=$(PGSQL_PASSWORD) \
	        -var APP_HOST=$(APP_HOST) \
			-var PGSQL_HOST=$(PGSQL_HOST) -var REDIS_HOST=$(REDIS_HOST) -var PGSQL_PORT=$(PGSQL_PORT) -var REDIS_PORT=$(REDIS_PORT) -var REDIS_SSL=$(REDIS_SSL) \
			-var EXTERNAL_PGSQL_SVC_ENABLED=$(EXTERNAL_PGSQL_SVC_ENABLED) -var EXTERNAL_REDIS_SVC_ENABLED=$(EXTERNAL_REDIS_SVC_ENABLED) \
			-var SSO_MODE=$(SSO_MODE) -var OIDC_AUTHORIZATION_ENDPOINT=$(OIDC_AUTHORIZATION_ENDPOINT) \
			-var OIDC_CLIENT_ID=$(OIDC_CLIENT_ID) -var OIDC_CLIENT_SECRET=$(OIDC_CLIENT_SECRET) -var OIDC_END_SESSION_ENDPOINT=$(OIDC_END_SESSION_ENDPOINT) \
			-var OIDC_METADATA_ENDPOINT=$(OIDC_METADATA_ENDPOINT) -var OIDC_TOKEN_ENDPOINT=$(OIDC_TOKEN_ENDPOINT) -var OIDC_URL_MODE=$(OIDC_URL_MODE) \
			-var OIDC_USERINFO_ENDPOINT=$(OIDC_USERINFO_ENDPOINT) -var SAML_AUTHN_DESTINATION=$(SAML_AUTHN_DESTINATION) \
			-var SAML_LOGOUT_DESTINATION=$(SAML_LOGOUT_DESTINATION) -var SAML_ISSUER=$(SAML_ISSUER) -var SAML_SP_KEY=$(SAML_SP_KEY) \
			-var SAML_SP_CERT=$(SAML_SP_CERT) -var SAML_IDP_METADATA=$(SAML_IDP_METADATA) -var SAML_IDP_CERT=$(SAML_IDP_CERT) \
			-var ALLOWED_DOMAINS=$(ALLOWED_DOMAINS) -var CA_ENABLED=$(CA_ENABLED) -var PGSQL_USER=$(PGSQL_USER) -var PGSQL_DB=$(PGSQL_DB) -var AWS_REDIS=$(AWS_REDIS) \
		-var PG_CLOUD=$(PG_CLOUD) -var MESH_ENABLED=$(MESH_ENABLED) -var SSO_EXPIRATION_OVERRIDE=$(SSO_EXPIRATION_OVERRIDE) -var TRACING_ENABLED=$(TRACING_ENABLED) \
		 -var INTERNAL_OTPL_ENABLED=$(INTERNAL_OTPL_ENABLED) \
		-var IMAGEGEN_PLUGIN_ENABLED=$(IMAGEGEN_PLUGIN_ENABLED) -var DEEPWIKI_PLUGIN_ENABLED=$(DEEPWIKI_PLUGIN_ENABLED) -var INVENTORY_PLUGIN_ENABLED=$(INVENTORY_PLUGIN_ENABLED) \
		-var PLUGINS_INITIAL_TOKEN=$(PLUGINS_INITIAL_TOKEN) -var PLUGINS_INITIAL_PROJECT=$(PLUGINS_INITIAL_PROJECT) \
		-var PG_CUSTOM_CONFIG_ENABLED=$(PG_CUSTOM_CONFIG_ENABLED) \
		-var GRAFANA_MCP_ENABLED=$(GRAFANA_MCP_ENABLED) -var GRAFANA_MCP_TRANSPORT=$(GRAFANA_MCP_TRANSPORT) -var GRAFANA_MCP_ADDRESS=$(GRAFANA_MCP_ADDRESS) \
		-var GRAFANA_MCP_ENDPOINT_PATH=$(GRAFANA_MCP_ENDPOINT_PATH) -var GRAFANA_MCP_ALLOWED_HOSTS=$(GRAFANA_MCP_ALLOWED_HOSTS) -var GRAFANA_MCP_LOG_LEVEL=$(GRAFANA_MCP_LOG_LEVEL) \
		-var GRAFANA_MCP_ALLOWED_ORIGINS=$(GRAFANA_MCP_ALLOWED_ORIGINS) -var GRAFANA_MCP_DISABLE_WRITE=$(GRAFANA_MCP_DISABLE_WRITE) \
		-var 'GRAFANA_URL=$(GRAFANA_URL)' -var 'GRAFANA_SERVICE_ACCOUNT_TOKEN=$(GRAFANA_SERVICE_ACCOUNT_TOKEN)' -var GRAFANA_ORG_ID=$(GRAFANA_ORG_ID) -var 'GRAFANA_EXTRA_HEADERS=$(GRAFANA_EXTRA_HEADERS)' \
		-var ADO_MCP_ENABLED=$(ADO_MCP_ENABLED) -var 'ADO_MCP_IMAGE=$(ADO_MCP_IMAGE)' -var 'ADO_MCP_ORGANIZATION=$(ADO_MCP_ORGANIZATION)' \
		-var ADO_MCP_AUTHENTICATION=$(ADO_MCP_AUTHENTICATION) -var ADO_MCP_TRANSPORT=$(ADO_MCP_TRANSPORT) -var ADO_MCP_HOST=$(ADO_MCP_HOST) -var ADO_MCP_PORT=$(ADO_MCP_PORT) \
		-var 'ADO_MCP_ALLOWED_HOSTS=$(ADO_MCP_ALLOWED_HOSTS)' -var 'ADO_MCP_PERSONAL_ACCESS_TOKEN=$(ADO_MCP_PERSONAL_ACCESS_TOKEN)' \
		-var ADO_MCP_LEGACY_API_KEY_ENABLED=$(ADO_MCP_LEGACY_API_KEY_ENABLED) -var 'ADO_MCP_API_KEY=$(ADO_MCP_API_KEY)' \
		-var ADO_MCP_MULTIPLE_API_KEYS_ENABLED=$(ADO_MCP_MULTIPLE_API_KEYS_ENABLED) -var 'ADO_MCP_API_KEYS=$(ADO_MCP_API_KEYS)'

clean_tf:
	@echo "Removing files and configs rendered by terraform"
	@rm -f ./tmpl/.terraform.lock
	@rm -rf ./tmpl/.terraform
	@rm -f ./tmpl/terraform.tfstate
	@rm -f ./tmpl/terraform.tfstate.backup
	@rm -f ./tmpl/.terraform.lock.hcl
	@rm -f docker-compose.yml
	@rm -f ./envs/override.env
	@rm -f ./envs/grafana_mcp.env
	@rm -f ./envs/ado_mcp.env
	@rm -f ./pylon_auth/pylon.yml
	@rm -f ./pylon_auth/configs/auth_core.yml
	@rm -f ./pylon_auth/configs/auth_oidc.yml
	@rm -f ./pylon_auth/configs/auth_saml.yml
	@rm -f ./pylon_auth/configs/auth_init.yml
	@rm -f ./pylon_auth/configs/auth_form.yml
	@rm -f ./pylon_auth/configs/bootstrap.yml
	@rm -f ./pylon_main/pylon.yml
	@rm -f ./pylon_main/configs/admin.yml
	@rm -f ./pylon_main/configs/auth.yml
	@rm -f ./pylon_main/configs/bootstrap.yml
	@rm -f ./pylon_main/configs/elitea_core.yml
	@rm -f ./pylon_main/configs/logging_hub.yml
	@rm -f ./pylon_main/configs/monitoring_hub.yml
	@rm -f ./pylon_main/configs/monitoring.yml
	@rm -f ./pylon_main/configs/shared.yml
	@rm -f ./pylon_main/configs/theme.yml
	@rm -f ./pylon_main/configs/worker_client.yml
	@rm -f ./pylon_indexer/pylon.yml
	@rm -f ./pylon_indexer/configs/bootstrap.yml
	@rm -f ./pylon_indexer/configs/indexer_worker.yml
	@rm -f ./pylon_indexer/configs/monitoring.yml
	@rm -f ./pylon_indexer/configs/runtime_engine_litellm.yml
	@rm -f ./pylon_indexer/configs/worker_core.yml
	@rm -f ./pylon_auth/configs/tracing.yml
	@rm -f ./pylon_main/configs/tracing.yml
	@rm -f ./pylon_indexer/configs/tracing.yml
	@rm -f ./pylon_deepwiki/pylon.yml
	@rm -f ./pylon_deepwiki/configs/bootstrap.yml
	@rm -f ./pylon_deepwiki/configs/deepwiki_plugin.yml
	@rm -f ./pylon_imagegen/pylon.yml
	@rm -f ./pylon_imagegen/configs/bootstrap.yml
	@rm -f ./pylon_imagegen/configs/imagegen.yml
	@rm -f ./pylon_inventory/pylon.yml
	@rm -f ./pylon_inventory/configs/bootstrap.yml
	@rm -f ./pylon_inventory/configs/inventory_plugin.yml
	@rm -f ./pylon_otpl/configs/config.yml
	@echo "Done"

clean_images:
	@echo "This action removes Docker images used in Elitea!"\
    @docker image rm redis || true \
    @docker image rm ghcr.io/eliteaai/pylon || true\
    @docker image rm pgvector/pgvector || true\
	@echo "Cleanup complete."

clean_volumes:
	@echo "This action removes Docker volumes!"
	@printf "%s" " Type 'remove' to delete volumes: " ; \
	IFS= read -r answer ; \
	if [ $$answer = "remove" ]; then \
		vols=$$(docker volume ls -q --filter name=pgvector-data --filter name=postgres-data --filter name=redis-data); \
		docker volume prune -f; \
		if [ -n "$$vols" ]; then docker volume rm $$vols; else echo "No volumes to remove"; fi; \
	else \
		echo "Skipped."; \
	fi
	@echo "Cleanup complete."

clean_local_db:
	@printf "This action removes 'local DBs files'!"
	@printf "%s" " Type 'remove' to delete DBs files: " ; \
	IFS= read -r answer ; \
	if [ $$answer = "remove" ]; then \
	        rm -f pylon_auth/pylon.db; \
	        rm -f pylon_indexer/pylon.db; \
	        rm -f pylon_main/pylon.db; \
	        rm -f pylon_predicts/pylon.db; \
			$(call RMR,pylon_inventory/pylon.db); \
			$(call RMR,pylon_imagegen/pylon.db); \
			$(call RMR,pylon_deepwiki/pylon.db); \
	else \
	    echo "Skipped."; \
	        exit 0; \
	fi;

clean_cache:
	@printf "This action removes local 'plugins/' and 'requirements/'!"
	@printf "%s" " Type 'remove' to delete files: " ; \
	IFS= read -r answer ; \
	if [ $$answer = "remove" ]; then \
	        $(call RMR,pylon_auth/plugins); \
	        $(call RMR,pylon_indexer/plugins); \
	        $(call RMR,pylon_main/plugins); \
	        $(call RMR,pylon_auth/requirements); \
	        $(call RMR,pylon_indexer/requirements); \
	        $(call RMR,pylon_main/requirements); \
			$(call RMR,pylon_auth/cache); \
	        $(call RMR,pylon_indexer/cache); \
	        $(call RMR,pylon_main/cache); \
			$(call RMR,pylon_otpl/cache); \
			$(call RMR,pylon_inventory/cache); \
			$(call RMR,pylon_imagegen/cache); \
			$(call RMR,pylon_deepwiki/cache); \
			$(call RMR,pylon_inventory/requirements); \
			$(call RMR,pylon_imagegen/requirements); \
			$(call RMR,pylon_deepwiki/requirements); \
			$(call RMR,pylon_inventory/plugins); \
			$(call RMR,pylon_imagegen/plugins); \
			$(call RMR,pylon_deepwiki/plugins); \
	else \
	    echo "Skipped."; \
	        exit 0; \
	fi;
	@rm -rf .label

clean_start: clean_cache clean_local_db up
	@echo -e "\nFiles have been removed for the clean start"

full_clean: clean_local_db clean_cache clean_images clean_volumes clean_tf
	@$(call RMR,pgsql_conf/ pylon_auth/ pylon_indexer/ pylon_main/ pylon_predicts/ pylon_inventory/ pylon_imagegen/ pylon_deepwiki/ pylon_otpl/ envs/*.env)
	@rm -rf ./inputs.env
	@echo "All data and images has been removed"

check_config:
	@echo "Checking configuration..."
	@if [ ! -f envs/override.env ]; then \
		echo "override.env file not found"; \
		exit 1; \
	fi
	@docker compose -f docker-compose.yml config -q
