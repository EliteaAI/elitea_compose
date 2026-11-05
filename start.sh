#!/usr/bin/env bash
printf " \n"
printf " \n"
printf " Docker Compose                                            \n"
printf "  ______ _      _____ _______ ______               _____   \n"
printf " |  ____| |    |_   _|__   __|  ____|      /\\     |_____| \n"
printf " | |__  | |      | |    | |  | |__        /  \\      | |  \n"
printf " |  __| | |      | |    | |  |  __|      / /\\ \\     | |  \n"
printf " | |____| |____ _| |_   | |  | |____    / ____ \\   _| |_  \n"
printf " |______|______|_____|  |_|  |______|  /_/    \\_\\ |_____| \n"
printf "                                                               \n"
printf "                                                  v2.0.7      \n"
printf " \n"
printf " \n"
printf " \n"
printf " \n"
# --- Host detection / prerequisites (macOS, Ubuntu, Debian, RHEL family) ---
_fail() { echo "$*" >&2; exit 1; }
case "$(uname -s)" in
  Darwin) HOST_OS=macos; PREP_TARGET="" ;;
  Linux)
    _id=$(. /etc/os-release 2>/dev/null; echo "${ID:-} ${ID_LIKE:-}")
    case " $_id " in
      *" ubuntu "*|*" debian "*) HOST_OS=debian; PREP_TARGET=prepare_ubuntu ;;
      *" rhel "*|*" centos "*|*" rocky "*|*" fedora "*|*" almalinux "*) HOST_OS=rhel; PREP_TARGET=prepare_rocky ;;
      *) _fail "Unsupported Linux distribution: $_id"; return 1 2>/dev/null || exit 1 ;;
    esac ;;
  *) _fail "Unsupported OS: $(uname -s)"; return 1 2>/dev/null || exit 1 ;;
esac
export PATH="$PATH:$HOME/.local/bin"
printf "Detected host: %s\n" "$HOST_OS"

_ask() { printf "%s yes/no [default: yes]: " "$1"; IFS= read -r _a
  case "$(printf "%s" "${_a:-yes}" | tr '[:upper:]' '[:lower:]')" in y|yes) return 0 ;; *) return 1 ;; esac; }
_abort() { echo "$*" >&2; exit 1; }

# Already deployed? Stop our stack first: frees port 80 and lets us redeploy with new settings (volumes/data are kept).
if [ -f docker-compose.yml ] && docker compose version >/dev/null 2>&1 \
   && [ -n "$(docker compose -f docker-compose.yml ps -aq 2>/dev/null)" ]; then
  _ask "ELITEA is already deployed here. Stop it (data is kept) and redeploy with the new settings?" || _abort "Aborted: existing deployment left untouched."
  docker compose -f docker-compose.yml down || _abort "Could not stop the existing deployment."
fi

# Colored prerequisite report: "<name> installed ........ ✓ <version>" / "✗ missing"
if [ -t 1 ]; then _G=$(printf '\033[32m'); _R=$(printf '\033[31m'); _N=$(printf '\033[0m'); else _G=; _R=; _N=; fi
_check() {  # $1=label $2=version command (non-zero exit = missing)
  _v=$(eval "$2" 2>/dev/null | head -n1)
  _dots=$(printf '%*s' $((34 - ${#1})) '' | tr ' ' '.')
  if [ -n "$_v" ]; then printf "%s installed %s %s✓%s %s\n" "$1" "$_dots" "$_G" "$_N" "$_v"
  else printf "%s installed %s %s✗ missing%s\n" "$1" "$_dots" "$_R" "$_N"; fi
}
printf "\nChecking prerequisites...\n"
_check "make"           "make --version || gmake --version"
_check "docker"         "docker --version"
_check "docker compose" "docker compose version --short"
_check "terraform"      "$HOME/.local/bin/terraform version"

# Primary IPv4 of this host (interface with the default route); empty if unknown.
_detect_ip() {
  _ip=""
  if [ "$HOST_OS" = "macos" ]; then
    _if=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
    [ -n "$_if" ] && _ip=$(ipconfig getifaddr "$_if" 2>/dev/null)
  else
    _ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<NF;i++) if($i=="src") {print $(i+1); exit}}')
    [ -z "$_ip" ] && _ip=$(hostname -I 2>/dev/null | awk '{print $1}')
  fi
  printf "%s" "$_ip"
}

DETECTED_IP=$(_detect_ip)
printf "%s %s %s✓%s %s\n" "host address" "$(printf '%*s' 31 '' | tr ' ' '.')" "$_G" "$_N" "${DETECTED_IP:-not detected, will use localhost}"

# Port 80: busy (something listens) or privileged ports blocked (rootless Docker) -> default to 8080
DEFAULT_HTTP_PORT=80; PORT_NOTE=""
_port_busy() { (exec 3<>/dev/tcp/127.0.0.1/80) >/dev/null 2>&1; }
_rootless() { docker info --format '{{.SecurityOptions}}' 2>/dev/null | grep -q rootless; }
_unpriv=$(cat /proc/sys/net/ipv4/ip_unprivileged_port_start 2>/dev/null || echo 0)
if _port_busy; then
  DEFAULT_HTTP_PORT=8080; PORT_NOTE="Port 80 is already in use on this host, so port 8080 is used instead."
elif _rootless && [ "$_unpriv" -gt 80 ]; then
  DEFAULT_HTTP_PORT=8080; PORT_NOTE="Rootless Docker cannot bind port 80 (ip_unprivileged_port_start=$_unpriv), so port 8080 is used instead."
fi
if [ "$DEFAULT_HTTP_PORT" = 80 ]; then printf "%s %s %s✓%s free\n" "port 80" "$(printf '%*s' 36 '' | tr ' ' '.')" "$_G" "$_N"
else printf "%s %s %s✗%s unavailable -> using 8080\n" "port 80" "$(printf '%*s' 36 '' | tr ' ' '.')" "$_R" "$_N"; fi

# Disk space (same threshold as `make up`)
FREE_SPACE_THRESHOLD=${FREE_SPACE_THRESHOLD:-30}
_free=$(df -k . | awk 'NR==2 { printf "%d", $4/1024/1024 }')
if [ "${_free:-0}" -ge "$FREE_SPACE_THRESHOLD" ]; then
  printf "%s %s %s✓%s %sG free (need %sG)\n" "disk space" "$(printf '%*s' 33 '' | tr ' ' '.')" "$_G" "$_N" "$_free" "$FREE_SPACE_THRESHOLD"
else
  printf "%s %s %s✗%s only %sG free (need %sG)\n" "disk space" "$(printf '%*s' 33 '' | tr ' ' '.')" "$_R" "$_N" "$_free" "$FREE_SPACE_THRESHOLD"
  _ask "Not enough free disk space. Continue anyway? (no = abort)" 2>/dev/null || _abort "Free up disk space and re-run."
fi
echo

# --- Prerequisites: make, curl/unzip (for Terraform), docker + compose, terraform ---
_pkg_install() {  # $@ = package names (same on apt/dnf/brew)
  case "$HOST_OS" in
    debian) sudo apt-get update && sudo apt-get install -y "$@" ;;
    rhel)   sudo dnf install -y "$@" ;;
    macos)  command -v brew >/dev/null 2>&1 || { echo "Homebrew is required: https://brew.sh" >&2; return 1; }
            brew install "$@" ;;
  esac
}

if ! command -v make >/dev/null 2>&1; then
  if [ "$HOST_OS" = "macos" ]; then
    _ask "'make' not found. Install it via Homebrew (brew install make; use gmake if needed)?" || _abort "make is required."
    _pkg_install make || _abort "Could not install make."
    command -v make >/dev/null 2>&1 || make() { gmake "$@"; }
  else
    _ask "'make' not found. Install it now (needs sudo)?" || _abort "make is required."
    _pkg_install make || _abort "Could not install make."
  fi
fi

if ! docker compose version >/dev/null 2>&1; then
  if [ -z "$PREP_TARGET" ]; then
    _ask "Docker not found. Install Docker Desktop via Homebrew (brew install --cask docker)?" || _abort "Docker is required."
    brew install --cask docker || _abort "Docker install failed."
    _abort "Start Docker Desktop once (open -a Docker), wait until it is running, then re-run start.sh."
  fi
  _ask "Docker / Docker Compose not found. Install now with 'make $PREP_TARGET' (needs sudo)?" || _abort "Docker is required."
  make "$PREP_TARGET" || _abort "Docker install failed."
fi
docker info >/dev/null 2>&1 || _abort "Docker daemon is not reachable (is it running, and is your user in the 'docker' group?)."

if [ ! -x "$HOME/.local/bin/terraform" ]; then
  command -v unzip >/dev/null 2>&1 || _pkg_install unzip || _abort "unzip is required to install Terraform."
  command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || _pkg_install curl || _abort "curl or wget is required."
  _ask "Terraform not found. Download it with 'make get_tools'?" || _abort "Terraform is required."
  make get_tools || _abort "Terraform install failed."
  [ -x "$HOME/.local/bin/terraform" ] || _abort "Terraform was not installed."
fi

printf "\nSetup mode:\n  1 - Quick start (defaults, all optional plugins on, passwords autogenerated)\n  2 - Customize\n"
printf "Choose [default: 1]: "
IFS= read -r _mode
case "${_mode:-1}" in 2) QUICK=false ;; *) QUICK=true ;; esac

if [ "$QUICK" = "true" ]; then
  export HTTP_HOST_PORT=$DEFAULT_HTTP_PORT LB_HTTPS=false SELF_HTTPS=false PROXY_ENABLED=false CA_ENABLED=false
  export SSO_ENABLED=false SSO_MODE=form ALLOWED_DOMAINS="centry.user"
  export APP_HOST="${APP_HOST:-${DETECTED_IP:-localhost}}"
  export PYLON_VER=1.2.28 TOOLS_ENABLED=false ELITEA_RELEASE=2.0.7 ELITEA_REMOTE_REPO=1
  export REDIS_VER=8.10.3-alpine PG_VECTOR_VERSION=0.8.7-pg18-trixie PGSQL_USER=eliteausr POSTGRES_USER=eliteausr PGSQL_DB=eliteadb POSTGRES_DB=eliteadb
  export PG_CLOUD=false EXTERNAL_PGSQL_SVC_ENABLED=false PG_CUSTOM_CONFIG_ENABLED=false
  export SHARED_REDIS=false AWS_REDIS=false REDIS_SSL=false EXTERNAL_REDIS_SVC_ENABLED=false EXTERNAL_SVC_ENABLED=false
  export AUTOCREATE_DB=true MESH_ENABLED=true TRACING_ENABLED=true INTERNAL_OTPL_ENABLED=false
  export DEEPWIKI_PLUGIN_ENABLED=true IMAGEGEN_PLUGIN_ENABLED=true INVENTORY_PLUGIN_ENABLED=true
  export GRAFANA_MCP_ENABLED=false ADO_MCP_ENABLED=false
  _gen_password() { LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 20; }
  # Re-run: keep passwords from the previous deployment (existing DB/Redis volumes were initialised with them)
  _saved() { [ -f inputs.env ] && sed -n "s/^export $1=//p" inputs.env | tail -n1; }
  for _v in ADMIN_PASSWORD REDIS_PASSWORD PGSQL_PASSWORD; do
    eval "[ -n \"\$$_v\" ] || $_v=\$(_saved $_v)"
    eval "[ -n \"\$$_v\" ] || $_v=\$(_gen_password)"
  done
  export ADMIN_PASSWORD REDIS_PASSWORD PGSQL_PASSWORD
  SAVE_ANSWER=yes
else
printf "Configuring network settings...\n"
printf "HTTP port [default: %s]: " "$DEFAULT_HTTP_PORT"
IFS= read -r http_port
HTTP_HOST_PORT=${http_port:-$DEFAULT_HTTP_PORT}
export HTTP_HOST_PORT

printf "External LB has TLS? yes/no [default: no]: "
IFS= read -r lb_tls_enabled
lb_tls_norm=$(printf "%s" "${lb_tls_enabled:-}" | tr '[:upper:]' '[:lower:]')
case "$lb_tls_norm" in
  true|1|yes|y) LB_HTTPS=true ;;
  *)            LB_HTTPS=false ;;
esac
unset lb_tls_norm
export LB_HTTPS

if [ "$LB_HTTPS" = "false" ]; then
  printf "ELITEA will serve HTTPS itself without external LB? yes/no [default: no]: "
  IFS= read -r self_tls_enabled
  self_tls_norm=$(printf "%s" "${self_tls_enabled:-}" | tr '[:upper:]' '[:lower:]')
  case "$self_tls_norm" in
    true|1|yes|y)
      SELF_HTTPS=true
      printf '\n Put TLS certs in cacerts/ directory and name them "server.crt" and "server.key" ! \n'
      ;;
    *)
      SELF_HTTPS=false
      ;;
  esac
  unset self_tls_norm
  export SELF_HTTPS
else
export SELF_HTTPS=false
fi

if [ "$SELF_HTTPS" = "true" ]; then
  printf "HTTPS port [default: 443]: "
  IFS= read -r https_port
  HTTPS_HOST_PORT=${https_port:-443}
  export HTTPS_HOST_PORT
fi

printf "Enter host IP address or DNS [default: %s]: " "${DETECTED_IP:-localhost}"
IFS= read -r ip_addr
APP_HOST=${ip_addr:-${DETECTED_IP:-localhost}}
export APP_HOST
if [ -z "$APP_HOST" ]; then
  echo "Host IP address or DNS cannot be empty!" >&2
  return 1 2>/dev/null || exit 1
fi

printf "Use internal company proxy? yes/no [default: no]: "
IFS= read -r proxy_enabled
proxy_norm=$(printf "%s" "${proxy_enabled:-}" | tr '[:upper:]' '[:lower:]')
case "$proxy_norm" in
  true|1|yes|y) PROXY_ENABLED=true ;;
  *)            PROXY_ENABLED=false ;;
esac
unset proxy_norm
export PROXY_ENABLED

if [ "$PROXY_ENABLED" = "true" ]; then
  printf "Enter http proxy: "
  IFS= read -r PROXY_ENABLED_HTTP
  export PROXY_ENABLED_HTTP
  printf "Enter https proxy: "
  IFS= read -r PROXY_ENABLED_HTTPS
  export PROXY_ENABLED_HTTPS
  printf "Enter no_proxy: "
  IFS= read -r PROXY_ENABLED_NO_PROXY
  export PROXY_ENABLED_NO_PROXY
fi

printf "Use custom external CA? yes/no [default: no]: "
IFS= read -r custom_ca_enabled
custom_ca_norm=$(printf "%s" "${custom_ca_enabled:-no}" | tr '[:upper:]' '[:lower:]')
case "$custom_ca_norm" in
  true|1|yes|y) CA_ENABLED=true
                printf "\n Put CA certificate in cacerts/ dir and name it "ca.crt" ! \n" ;;
  *)            CA_ENABLED=false ;;
esac
unset custom_ca_norm
export CA_ENABLED


# SSO Configuration
printf "\nUse SSO service? [default: no]: "
IFS= read -r sso_enabled
sso_norm=$(printf "%s" "${sso_enabled:-no}" | tr '[:upper:]' '[:lower:]')
case "$sso_norm" in
  true|1|yes|y) SSO_ENABLED=true ;;
  *)            SSO_ENABLED=false
                export SSO_MODE=form ;;
esac
unset sso_norm
export SSO_ENABLED

if [ "$SSO_ENABLED" = "true" ]; then
  printf "Enter SSO mode (form/OIDC/SAML) [default: form]: "
  IFS= read -r sso_mode
  SSO_MODE=$(printf "%s" "${sso_mode:-form}" | tr '[:upper:]' '[:lower:]')
  export SSO_MODE
fi

if [ "$SSO_MODE" = "oidc" ]; then
  printf "Enter OIDC_AUTHORIZATION_ENDPOINT: "
  IFS= read -r OIDC_AUTHORIZATION_ENDPOINT
  export OIDC_AUTHORIZATION_ENDPOINT

  printf "Enter OIDC_CLIENT_ID: "
  IFS= read -r OIDC_CLIENT_ID
  export OIDC_CLIENT_ID

  printf "Enter OIDC_CLIENT_SECRET [HIDDEN]: "
  if [ -t 0 ]; then stty -echo 2>/dev/null; fi
  IFS= read -r OIDC_CLIENT_SECRET
  if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
  export OIDC_CLIENT_SECRET

  printf "Enter OIDC_END_SESSION_ENDPOINT: "
  IFS= read -r OIDC_END_SESSION_ENDPOINT
  export OIDC_END_SESSION_ENDPOINT

  printf "Enter OIDC_METADATA_ENDPOINT: "
  IFS= read -r OIDC_METADATA_ENDPOINT
  export OIDC_METADATA_ENDPOINT

  printf "Enter OIDC_TOKEN_ENDPOINT: "
  IFS= read -r OIDC_TOKEN_ENDPOINT
  export OIDC_TOKEN_ENDPOINT

  printf "Enter OIDC_URL_MODE [default: external]: "
  IFS= read -r oidc_url_mode
  OIDC_URL_MODE=${oidc_url_mode:-external}
  export OIDC_URL_MODE

  printf "Enter OIDC_USERINFO_ENDPOINT: "
  IFS= read -r OIDC_USERINFO_ENDPOINT
  export OIDC_USERINFO_ENDPOINT
fi

if [ "$SSO_MODE" = "saml" ]; then
  printf "Enter SAML_AUTHN_DESTINATION: "
  IFS= read -r SAML_AUTHN_DESTINATION
  export SAML_AUTHN_DESTINATION

  printf "Enter SAML_LOGOUT_DESTINATION: "
  IFS= read -r SAML_LOGOUT_DESTINATION
  export SAML_LOGOUT_DESTINATION

  printf "Insert SAML_SP_KEY certificate (including -----BEGIN/END CERTIFICATE-----), then Ctrl-D:\n"
  SAML_SP_KEY="$(cat)"
  export SAML_SP_KEY

  printf "\n Insert SAML_SP_CERT certificate (including -----BEGIN/END CERTIFICATE-----), then Ctrl-D:\n"
  SAML_SP_CERT="$(cat)"
  export SAML_SP_CERT

  printf "\n Enter SAML_IDP_METADATA URL (EMPTY IF NOT USED): "
  IFS= read -r SAML_IDP_METADATA
  SAML_IDP_METADATA=${SAML_IDP_METADATA:-}
  export SAML_IDP_METADATA

  if [ -z "$SAML_IDP_METADATA" ]; then
    printf "\n Insert SAML_IDP_CERT certificate (including -----BEGIN/END CERTIFICATE-----), then Ctrl-D:\n"
    SAML_IDP_CERT="$(cat)"
    export SAML_IDP_CERT
  fi
  printf "Enter SAML_ISSUER: "
  IFS= read -r SAML_ISSUER
  SAML_ISSUER=${SAML_ISSUER:-}
  export SAML_ISSUER
  fi

if [ "$SSO_ENABLED" = "true" ]; then
  printf "Enter Allowed domains (comma-separated): "
  IFS= read -r allowed_domains
  ALLOWED_DOMAINS="centry.user,${allowed_domains:-}"
  export ALLOWED_DOMAINS
else
  export ALLOWED_DOMAINS="centry.user"
fi
# End SSO Configuration

printf "\nConfiguring ELITEA...\n"

printf "Enter Pylon version [default: 1.2.28]: "
IFS= read -r pylon_ver
PYLON_VER=${pylon_ver:-1.2.28}
export PYLON_VER

printf "Enable Pylon tools image? yes/no [default: no]: "
IFS= read -r tools_enabled
TOOLS_ENABLED=${tools_enabled:-no}

if [[ "$TOOLS_ENABLED" =~ ^[Yy][Ee][Ss]$ ]]; then
    TOOLS_ENABLED=true
else
    TOOLS_ENABLED=false
fi
export TOOLS_ENABLED

printf "Enter elita release [ (2.0.6, 2.0.7), default: 2.0.7]: "
IFS= read -r al_release
ELITEA_RELEASE=${al_release:-2.0.7}
export ELITEA_RELEASE

printf "Enter ELITEA repository [ (1 - standard, 2 - internal repo ), default: 1]: "
IFS= read -r al_remote_repo
ELITEA_REMOTE_REPO=${al_remote_repo:-1}
export ELITEA_REMOTE_REPO

printf "Would you use external PGSQL service? yes/no [default: no]: "
IFS= read -r external_pgsql_enabled
external_pgsql_norm=$(printf "%s" "${external_pgsql_enabled:-no}" | tr '[:upper:]' '[:lower:]')
case "$external_pgsql_norm" in
  true|1|yes|y)
    printf "input PGSQL Host: "
    IFS= read -r PGSQL_HOST
    export PGSQL_HOST

    printf "input PGSQL PORT [default: 5432]: "
    IFS= read -r PGSQL_PORT
    export PGSQL_PORT="${PGSQL_PORT:-5432}"

    printf "input PGSQL user [default: eliteausr]: "
    IFS= read -r PGSQL_USER
    export PGSQL_USER="${PGSQL_USER:-eliteausr}"

    printf "input PGSQL db [default: eliteadb]: "
    IFS= read -r PGSQL_DB
    export PGSQL_DB="${PGSQL_DB:-eliteadb}"

    printf "PGSQL in Cloud, skip creating PG Vector [default: no]: "
    IFS= read -r PG_CLOUD_ANSWER
    PG_CLOUD_norm=$(printf "%s" "${PG_CLOUD_ANSWER:-}" | tr '[:upper:]' '[:lower:]')
    case "$PG_CLOUD_norm" in
      true|1|yes|y) PG_CLOUD=true ;;
      *)            PG_CLOUD=false ;;
    esac
    export PG_CLOUD="${PG_CLOUD:-false}"
    export EXTERNAL_PGSQL_SVC_ENABLED=true
    ;;
  *)
    PG_VECTOR_VERSION=0.8.7-pg18-trixie
    export PG_VECTOR_VERSION
    printf "input PGSQL user [default: eliteausr]: "
    IFS= read -r PGSQL_USER
    export PGSQL_USER="${PGSQL_USER:-eliteausr}"
    export POSTGRES_USER="${PGSQL_USER:-eliteausr}"
    printf "input PGSQL db [default: eliteadb]: "
    IFS= read -r PGSQL_DB
    export PGSQL_DB="${PGSQL_DB:-eliteadb}"
    export POSTGRES_DB="${PGSQL_DB:-eliteadb}"
    export PG_CLOUD=false
    export EXTERNAL_PGSQL_SVC_ENABLED=false
    printf "Use PGSQL custom config? yes/no [default: no]: "
    IFS= read -r pg_custom_config_enabled
    pg_custom_config_norm=$(printf "%s" "${pg_custom_config_enabled:-no}" | tr '[:upper:]' '[:lower:]')
    case "$pg_custom_config_norm" in
      true|1|yes|y) PG_CUSTOM_CONFIG_ENABLED=true ;;
      *)            PG_CUSTOM_CONFIG_ENABLED=false ;;
    esac
    export PG_CUSTOM_CONFIG_ENABLED
    ;;
esac
unset external_pgsql_norm


printf "Would you use external REDIS service? yes/no [default: no]: "
IFS= read -r external_redis_enabled
external_redis_norm=$(printf "%s" "${external_redis_enabled:-no}" | tr '[:upper:]' '[:lower:]')
case "$external_redis_norm" in
  true|1|yes|y)
    printf "input REDIS Host: "
    IFS= read -r REDIS_HOST
    export REDIS_HOST

    printf "input REDIS PORT [default: 6379]: "
    IFS= read -r REDIS_PORT
    export REDIS_PORT="${REDIS_PORT:-6379}"

    printf "Enable REDIS SSL [default: no]: "
    IFS= read -r REDIS_SSL_ANSWER
    redis_ssl_norm=$(printf "%s" "${REDIS_SSL_ANSWER:-}" | tr '[:upper:]' '[:lower:]')
    case "$redis_ssl_norm" in
      true|1|yes|y) REDIS_SSL=true ;;
      *)            REDIS_SSL=false ;;
    esac
    export REDIS_SSL

    printf "Redis in AWS [default: no]: "
    IFS= read -r AWS_REDIS_ANSWER
    aws_redis_norm=$(printf "%s" "${AWS_REDIS_ANSWER:-}" | tr '[:upper:]' '[:lower:]')
    case "$aws_redis_norm" in
      true|1|yes|y) AWS_REDIS=true ;;
      *)            AWS_REDIS=false ;;
    esac
    export AWS_REDIS="${AWS_REDIS:-false}"
    export EXTERNAL_REDIS_SVC_ENABLED=true
    ;;
  *)
    printf "Redis version [default: 8.10.3-alpine]: "
    IFS= read -r REDIS_VER
    export REDIS_VER="${REDIS_VER:-8.10.3-alpine}"
    export SHARED_REDIS=false
    export AWS_REDIS=false
    export REDIS_SSL=false
    export EXTERNAL_REDIS_SVC_ENABLED=false
    ;;
esac
unset external_redis_norm

if [ "${EXTERNAL_PGSQL_SVC_ENABLED}" = "true" ] && [ "${EXTERNAL_REDIS_SVC_ENABLED}" = "true" ]; then
  export EXTERNAL_SVC_ENABLED=true
else
  export EXTERNAL_SVC_ENABLED=false
fi

printf "Enable auto config [default: yes]: "
IFS= read -r auto_config_enabled
auto_config_norm=$(printf "%s" "${auto_config_enabled:-yes}" | tr '[:upper:]' '[:lower:]')
case "$auto_config_norm" in
  true|1|yes|y) AUTOCREATE_DB=true
                export AUTOCREATE_DB ;;
  *)            AUTOCREATE_DB=false
                export AUTOCREATE_DB ;;
esac

printf "Enable Mesh [default: yes]: "
IFS= read -r mesh_enabled
mesh_norm=$(printf "%s" "${mesh_enabled:-yes}" | tr '[:upper:]' '[:lower:]')
case "$mesh_norm" in
  true|1|yes|y) MESH_ENABLED=true
                export MESH_ENABLED ;;
  *)            MESH_ENABLED=false
                export MESH_ENABLED ;;
esac

printf "Enable Tracing [default: yes]: "
IFS= read -r tracing_enabled
tracing_norm=$(printf "%s" "${tracing_enabled:-yes}" | tr '[:upper:]' '[:lower:]')
case "$tracing_norm" in
  true|1|yes|y) TRACING_ENABLED=true
                export TRACING_ENABLED ;;
  *)            TRACING_ENABLED=false
                export TRACING_ENABLED ;;
esac


printf "\nOptional containers/plugins (enter numbers separated by spaces):\n"
printf "  1 - DeepWiki\n"
printf "  2 - ImageGen\n"
printf "  3 - Inventory\n"
printf "  4 - All\n"
printf "Enable [default: none]: "
IFS= read -r plugins_input
DEEPWIKI_PLUGIN_ENABLED=false
IMAGEGEN_PLUGIN_ENABLED=false
INVENTORY_PLUGIN_ENABLED=false
case "$plugins_input" in
  *4*)
    DEEPWIKI_PLUGIN_ENABLED=true
    IMAGEGEN_PLUGIN_ENABLED=true
    INVENTORY_PLUGIN_ENABLED=true
    ;;
  *)
    case "$plugins_input" in *1*) DEEPWIKI_PLUGIN_ENABLED=true ;; esac
    case "$plugins_input" in *2*) IMAGEGEN_PLUGIN_ENABLED=true ;; esac
    case "$plugins_input" in *3*) INVENTORY_PLUGIN_ENABLED=true ;; esac
    ;;
esac
export DEEPWIKI_PLUGIN_ENABLED IMAGEGEN_PLUGIN_ENABLED INVENTORY_PLUGIN_ENABLED

printf "\nOptional containers/mcp servers (enter numbers separated by spaces):\n"
printf "  1 - Grafana MCP\n"
printf "  2 - Azure DevOps MCP\n"
printf "  3 - All\n"
printf "Enable [default: none]: "
IFS= read -r mcp_input
GRAFANA_MCP_ENABLED=false
ADO_MCP_ENABLED=false
case "$mcp_input" in
  *3*)
    GRAFANA_MCP_ENABLED=true
    ADO_MCP_ENABLED=true
    ;;
  *)
    case "$mcp_input" in *1*) GRAFANA_MCP_ENABLED=true ;; esac
    case "$mcp_input" in *2*) ADO_MCP_ENABLED=true ;; esac
    ;;
esac
export GRAFANA_MCP_ENABLED ADO_MCP_ENABLED

if [ "$GRAFANA_MCP_ENABLED" = "true" ]; then
  printf "Enter Grafana URL (for example, https://example.grafana.net): "
  IFS= read -r GRAFANA_URL
  export GRAFANA_URL
  printf "Enter GRAFANA_ORG_ID [default: 1]: "
  IFS= read -r GRAFANA_ORG_ID
  export GRAFANA_ORG_ID="${GRAFANA_ORG_ID:-1}"
  printf "Enter GRAFANA_SERVICE_ACCOUNT_TOKEN [HIDDEN]: "
  if [ -t 0 ]; then stty -echo 2>/dev/null; fi
  IFS= read -r GRAFANA_SERVICE_ACCOUNT_TOKEN
  if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
  export GRAFANA_SERVICE_ACCOUNT_TOKEN
  printf "Enter GRAFANA_EXTRA_HEADERS as JSON [default: {}]: "
  IFS= read -r GRAFANA_EXTRA_HEADERS
  export GRAFANA_EXTRA_HEADERS="${GRAFANA_EXTRA_HEADERS:-{}}"
  printf "Enter GRAFANA_MCP_TRANSPORT [default: streamable-http]: "
  IFS= read -r GRAFANA_MCP_TRANSPORT
  export GRAFANA_MCP_TRANSPORT="${GRAFANA_MCP_TRANSPORT:-streamable-http}"

  printf "Enter GRAFANA_MCP_ADDRESS [default: :8000]: "
  IFS= read -r GRAFANA_MCP_ADDRESS
  export GRAFANA_MCP_ADDRESS="${GRAFANA_MCP_ADDRESS:-:8000}"

  printf "Enter GRAFANA_MCP_ENDPOINT_PATH [default: /mcp]: "
  IFS= read -r GRAFANA_MCP_ENDPOINT_PATH
  export GRAFANA_MCP_ENDPOINT_PATH="${GRAFANA_MCP_ENDPOINT_PATH:-/mcp}"

  printf "Enter GRAFANA_MCP_ALLOWED_HOSTS [default: *]: "
  IFS= read -r GRAFANA_MCP_ALLOWED_HOSTS
  export GRAFANA_MCP_ALLOWED_HOSTS="${GRAFANA_MCP_ALLOWED_HOSTS:-*}"

  printf "Enter GRAFANA_MCP_LOG_LEVEL [default: info]: "
  IFS= read -r GRAFANA_MCP_LOG_LEVEL
  export GRAFANA_MCP_LOG_LEVEL="${GRAFANA_MCP_LOG_LEVEL:-info}"

  printf "Enter GRAFANA_MCP_ALLOWED_ORIGINS [default: empty]: "
  IFS= read -r GRAFANA_MCP_ALLOWED_ORIGINS
  export GRAFANA_MCP_ALLOWED_ORIGINS="${GRAFANA_MCP_ALLOWED_ORIGINS:-}"

  printf "Disable Grafana write operations? yes/no [default: yes]: "
  IFS= read -r grafana_mcp_disable_write
  grafana_mcp_disable_write_norm=$(printf "%s" "${grafana_mcp_disable_write:-yes}" | tr '[:upper:]' '[:lower:]')
  case "$grafana_mcp_disable_write_norm" in
    true|1|yes|y) GRAFANA_MCP_DISABLE_WRITE=true ;;
    *)            GRAFANA_MCP_DISABLE_WRITE=false ;;
  esac
  unset grafana_mcp_disable_write grafana_mcp_disable_write_norm
  export GRAFANA_MCP_DISABLE_WRITE
fi

if [ "$ADO_MCP_ENABLED" = "true" ]; then
  printf "Enter Azure DevOps organization: "
  IFS= read -r ADO_MCP_ORGANIZATION
  export ADO_MCP_ORGANIZATION

  printf "Enter ADO MCP image [default: ghcr.io/eliteaai/ado-mcp:v2.9.0-elitea.1]: "
  IFS= read -r ADO_MCP_IMAGE
  export ADO_MCP_IMAGE="${ADO_MCP_IMAGE:-ghcr.io/eliteaai/ado-mcp:v2.9.0-elitea.1}"

  printf "Enter base64 encoding of :<Azure DevOps PAT> [HIDDEN]: "
  if [ -t 0 ]; then stty -echo 2>/dev/null; fi
  IFS= read -r ADO_MCP_PERSONAL_ACCESS_TOKEN
  if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
  export ADO_MCP_PERSONAL_ACCESS_TOKEN

  printf "Enable shared MCP API key? yes/no [default: yes]: "
  IFS= read -r ado_mcp_legacy_key
  ado_mcp_legacy_key_norm=$(printf "%s" "${ado_mcp_legacy_key:-yes}" | tr '[:upper:]' '[:lower:]')
  case "$ado_mcp_legacy_key_norm" in
    true|1|yes|y) ADO_MCP_LEGACY_API_KEY_ENABLED=true ;;
    *)            ADO_MCP_LEGACY_API_KEY_ENABLED=false ;;
  esac
  unset ado_mcp_legacy_key ado_mcp_legacy_key_norm
  export ADO_MCP_LEGACY_API_KEY_ENABLED

  if [ "$ADO_MCP_LEGACY_API_KEY_ENABLED" = "true" ]; then
    printf "Enter shared MCP API key [HIDDEN]: "
    if [ -t 0 ]; then stty -echo 2>/dev/null; fi
    IFS= read -r ADO_MCP_API_KEY
    if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
    export ADO_MCP_API_KEY
  fi

  printf "Enable labeled MCP API keys? yes/no [default: no]: "
  IFS= read -r ado_mcp_multiple_keys
  ado_mcp_multiple_keys_norm=$(printf "%s" "${ado_mcp_multiple_keys:-no}" | tr '[:upper:]' '[:lower:]')
  case "$ado_mcp_multiple_keys_norm" in
    true|1|yes|y) ADO_MCP_MULTIPLE_API_KEYS_ENABLED=true ;;
    *)            ADO_MCP_MULTIPLE_API_KEYS_ENABLED=false ;;
  esac
  unset ado_mcp_multiple_keys ado_mcp_multiple_keys_norm
  export ADO_MCP_MULTIPLE_API_KEYS_ENABLED

  if [ "$ADO_MCP_MULTIPLE_API_KEYS_ENABLED" = "true" ]; then
    printf 'Enter labeled MCP API keys as JSON, for example {"alice":"key-a"} [HIDDEN]: '
    if [ -t 0 ]; then stty -echo 2>/dev/null; fi
    IFS= read -r ADO_MCP_API_KEYS
    if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
    export ADO_MCP_API_KEYS
  fi

  if [ "$ADO_MCP_LEGACY_API_KEY_ENABLED" != "true" ] && [ "$ADO_MCP_MULTIPLE_API_KEYS_ENABLED" != "true" ]; then
    printf "At least one MCP API key mode is required; enabling the shared key.\n"
    ADO_MCP_LEGACY_API_KEY_ENABLED=true
    printf "Enter shared MCP API key [HIDDEN]: "
    if [ -t 0 ]; then stty -echo 2>/dev/null; fi
    IFS= read -r ADO_MCP_API_KEY
    if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
    export ADO_MCP_LEGACY_API_KEY_ENABLED ADO_MCP_API_KEY
  fi

  ADO_MCP_AUTHENTICATION=pat
  ADO_MCP_TRANSPORT=http
  ADO_MCP_HOST=0.0.0.0
  ADO_MCP_PORT=3000
  ADO_MCP_ALLOWED_HOSTS=ado-mcp,localhost,127.0.0.1
  export ADO_MCP_AUTHENTICATION ADO_MCP_TRANSPORT ADO_MCP_HOST ADO_MCP_PORT ADO_MCP_ALLOWED_HOSTS
fi

printf "Enable internal OTEL collector (pylon_otpl)? yes/no [default: no]: "
IFS= read -r otpl_enabled
otpl_norm=$(printf "%s" "${otpl_enabled:-no}" | tr '[:upper:]' '[:lower:]')
case "$otpl_norm" in
  true|1|yes|y) INTERNAL_OTPL_ENABLED=true ;;
  *)            INTERNAL_OTPL_ENABLED=false ;;
esac
unset otpl_norm
export INTERNAL_OTPL_ENABLED


# Helper: generate a random 20-char alphanumeric password
_gen_password() { LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 20; }

printf "Enter ELITEA Admin password [HIDDEN, skip to autogenerate]: "
if [ -t 0 ]; then stty -echo 2>/dev/null; fi
IFS= read -r _tmp
if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
if [ -z "$_tmp" ]; then
  ADMIN_PASSWORD=$(_gen_password)
else
  ADMIN_PASSWORD=$_tmp
fi
unset _tmp
export ADMIN_PASSWORD

printf "Enter REDIS password [HIDDEN, skip to autogenerate]: "
if [ -t 0 ]; then stty -echo 2>/dev/null; fi
IFS= read -r _tmp
if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
if [ -z "$_tmp" ]; then
  REDIS_PASSWORD=$(_gen_password)
else
  REDIS_PASSWORD=$_tmp
fi
unset _tmp
export REDIS_PASSWORD

printf "Enter PGSQL password [HIDDEN, skip to autogenerate]: "
if [ -t 0 ]; then stty -echo 2>/dev/null; fi
IFS= read -r _tmp
if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
if [ -z "$_tmp" ]; then
  PGSQL_PASSWORD=$(_gen_password)
else
  PGSQL_PASSWORD=$_tmp
fi
unset _tmp
export PGSQL_PASSWORD

printf "Enter APP_AUTH_SECRET [HIDDEN,skip to autogenerate]: "
if [ -t 0 ]; then stty -echo 2>/dev/null; fi
IFS= read -r APP_AUTH_SECRET
if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
export APP_AUTH_SECRET

printf "Enter APP_MAIN_SECRET [HIDDEN, skip to autogenerate]: "
if [ -t 0 ]; then stty -echo 2>/dev/null; fi
IFS= read -r APP_MAIN_SECRET
if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
export APP_MAIN_SECRET

printf "Enter MASTER_KEY [HIDDEN, skip to autogenerate]: "
if [ -t 0 ]; then stty -echo 2>/dev/null; fi
IFS= read -r MASTER_KEY
if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
export MASTER_KEY

printf "Enter EVENT_HMAC_KEY [HIDDEN, skip to autogenerate]: "
if [ -t 0 ]; then stty -echo 2>/dev/null; fi
IFS= read -r EVENT_HMAC_KEY
if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
export EVENT_HMAC_KEY

printf "Enter RPC_HMAC_KEY [HIDDEN, skip to autogenerate]: "
if [ -t 0 ]; then stty -echo 2>/dev/null; fi
IFS= read -r RPC_HMAC_KEY
if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
export RPC_HMAC_KEY

printf "Enter EXPOSURE_HMAC_KEY [HIDDEN, skip to autogenerate]: "
if [ -t 0 ]; then stty -echo 2>/dev/null; fi
IFS= read -r EXPOSURE_HMAC_KEY
if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
export EXPOSURE_HMAC_KEY

printf "Enter INDEXER_HMAC_KEY [HIDDEN, skip to autogenerate]: "
if [ -t 0 ]; then stty -echo 2>/dev/null; fi
IFS= read -r INDEXER_HMAC_KEY
if [ -t 0 ]; then stty echo 2>/dev/null; printf "\n"; fi
export INDEXER_HMAC_KEY



fi

printf "\nDone. Environment variables exported for Terraform.\n"

if [ "$QUICK" != "true" ]; then
printf "Would you like to save and export all your inputs into file [yes/no default: yes]: "
IFS= read -r  SAVE_ANSWER
fi
   save_norm=$(printf "%s" "${SAVE_ANSWER:-yes}" | tr '[:upper:]' '[:lower:]')
   case "$save_norm" in
     true|1|yes|y) printf "exporting into file inputs.env...\n"
                      : > inputs.env
                      chmod 600 inputs.env
                      echo  "export HTTP_HOST_PORT=$HTTP_HOST_PORT" >> inputs.env
                      echo  "export LB_HTTPS=$LB_HTTPS" >> inputs.env
                      echo  "export SELF_HTTPS=$SELF_HTTPS" >> inputs.env
                      [ -n "$HTTPS_HOST_PORT" ] && echo  "export HTTPS_HOST_PORT=$HTTPS_HOST_PORT" >> inputs.env
                      echo  "export APP_HOST=$APP_HOST" >> inputs.env
                      echo  "export PROXY_ENABLED=$PROXY_ENABLED" >> inputs.env
                      [ -n "$PROXY_ENABLED_HTTP" ] && echo  "export PROXY_ENABLED_HTTP=$PROXY_ENABLED_HTTP" >> inputs.env
                      [ -n "$PROXY_ENABLED_HTTPS" ] && echo  "export PROXY_ENABLED_HTTPS=$PROXY_ENABLED_HTTPS" >> inputs.env
                      [ -n "$PROXY_ENABLED_NO_PROXY" ] && echo  "export PROXY_ENABLED_NO_PROXY=$PROXY_ENABLED_NO_PROXY" >> inputs.env
                      echo  "export CA_ENABLED=$CA_ENABLED" >> inputs.env
                      echo  "export SSO_ENABLED=$SSO_ENABLED" >> inputs.env
                      [ -n "$SSO_MODE" ] && echo  "export SSO_MODE=$SSO_MODE" >> inputs.env
                      [ -n "$OIDC_AUTHORIZATION_ENDPOINT" ] && echo  "export OIDC_AUTHORIZATION_ENDPOINT=$OIDC_AUTHORIZATION_ENDPOINT" >> inputs.env
                      [ -n "$OIDC_CLIENT_ID" ] && echo  "export OIDC_CLIENT_ID=$OIDC_CLIENT_ID" >> inputs.env
                      [ -n "$OIDC_CLIENT_SECRET" ] && echo  "export OIDC_CLIENT_SECRET=$OIDC_CLIENT_SECRET" >> inputs.env
                      [ -n "$OIDC_END_SESSION_ENDPOINT" ] && echo  "export OIDC_END_SESSION_ENDPOINT=$OIDC_END_SESSION_ENDPOINT" >> inputs.env
                      [ -n "$OIDC_METADATA_ENDPOINT" ] && echo  "export OIDC_METADATA_ENDPOINT=$OIDC_METADATA_ENDPOINT" >> inputs.env
                      [ -n "$OIDC_TOKEN_ENDPOINT" ] && echo  "export OIDC_TOKEN_ENDPOINT=$OIDC_TOKEN_ENDPOINT" >> inputs.env
                      [ -n "$OIDC_URL_MODE" ] && echo  "export OIDC_URL_MODE=$OIDC_URL_MODE" >> inputs.env
                      [ -n "$OIDC_USERINFO_ENDPOINT" ] && echo  "export OIDC_USERINFO_ENDPOINT=$OIDC_USERINFO_ENDPOINT" >> inputs.env
                      [ -n "$SAML_AUTHN_DESTINATION" ] && echo  "export SAML_AUTHN_DESTINATION=$SAML_AUTHN_DESTINATION" >> inputs.env
                      [ -n "$SAML_LOGOUT_DESTINATION" ] && echo  "export SAML_LOGOUT_DESTINATION=$SAML_LOGOUT_DESTINATION" >> inputs.env
                      [ -n "$SAML_SP_KEY" ] && echo  "export SAML_SP_KEY=$SAML_SP_KEY" >> inputs.env
                      [ -n "$SAML_SP_CERT" ]    && echo  "export SAML_SP_CERT=$SAML_SP_CERT" >> inputs.env
                      [ -n "$SAML_IDP_METADATA" ] && echo  "export SAML_IDP_METADATA=$SAML_IDP_METADATA" >> inputs.env
                      [ -n "$SAML_IDP_CERT" ] && echo  "export SAML_IDP_CERT=$SAML_IDP_CERT" >> inputs.env
                      [ -n "$SAML_ISSUER" ] && echo  "export SAML_ISSUER=$SAML_ISSUER" >> inputs.env
                      [ -n "$ALLOWED_DOMAINS" ] && echo  "export ALLOWED_DOMAINS=$ALLOWED_DOMAINS" >> inputs.env
                      echo  "export PYLON_VER=$PYLON_VER" >> inputs.env
                      echo  "export ELITEA_RELEASE=$ELITEA_RELEASE" >> inputs.env
                      echo  "export ELITEA_REMOTE_REPO=$ELITEA_REMOTE_REPO" >> inputs.env
                      echo  "export EXTERNAL_SVC_ENABLED=$EXTERNAL_SVC_ENABLED" >> inputs.env
                      [ -n "$PGSQL_HOST" ] && echo  "export PGSQL_HOST=$PGSQL_HOST" >> inputs.env
                      [ -n "$PGSQL_PORT" ] && echo  "export PGSQL_PORT=$PGSQL_PORT" >> inputs.env
                      [ -n "$PGSQL_USER" ] && echo  "export PGSQL_USER=$PGSQL_USER" >> inputs.env
                      [ -n "$PGSQL_USER" ] && echo  "export POSTGRES_USER=$PGSQL_USER" >> inputs.env
                      [ -n "$PGSQL_DB" ] && echo  "export PGSQL_DB=$PGSQL_DB" >> inputs.env
                      [ -n "$PGSQL_DB" ] && echo  "export POSTGRES_DB=$PGSQL_DB" >> inputs.env
                      [ -n "$REDIS_HOST" ] && echo  "export REDIS_HOST=$REDIS_HOST" >> inputs.env
                      [ -n "$REDIS_PORT" ] && echo  "export REDIS_PORT=$REDIS_PORT" >> inputs.env
                      [ -n "$MESH_ENABLED" ] && echo  "export MESH_ENABLED=$MESH_ENABLED" >> inputs.env
                      [ -n  "$AWS_REDIS" ] && echo  "export AWS_REDIS=$AWS_REDIS" >> inputs.env
                      [ -n  "$PG_CLOUD" ] && echo  "export PG_CLOUD=$PG_CLOUD" >> inputs.env
                      [ -n  "$AUTOCREATE_DB" ] && echo  "export AUTOCREATE_DB=$AUTOCREATE_DB" >> inputs.env
                      [ -n "$TRACING_ENABLED" ] && echo  "export TRACING_ENABLED=$TRACING_ENABLED" >> inputs.env
                      [ -n "$DEEPWIKI_PLUGIN_ENABLED" ] && echo  "export DEEPWIKI_PLUGIN_ENABLED=$DEEPWIKI_PLUGIN_ENABLED" >> inputs.env
                      [ -n "$IMAGEGEN_PLUGIN_ENABLED" ] && echo  "export IMAGEGEN_PLUGIN_ENABLED=$IMAGEGEN_PLUGIN_ENABLED" >> inputs.env
                      [ -n "$INVENTORY_PLUGIN_ENABLED" ] && echo  "export INVENTORY_PLUGIN_ENABLED=$INVENTORY_PLUGIN_ENABLED" >> inputs.env
                      [ -n "$INTERNAL_OTPL_ENABLED" ] && echo  "export INTERNAL_OTPL_ENABLED=$INTERNAL_OTPL_ENABLED" >> inputs.env
                      echo  "export ADMIN_PASSWORD=$ADMIN_PASSWORD" >> inputs.env
                      echo  "export REDIS_PASSWORD=$REDIS_PASSWORD" >> inputs.env
                      echo  "export PGSQL_PASSWORD=$PGSQL_PASSWORD" >> inputs.env
                      [ -n "$APP_AUTH_SECRET" ] && echo  "export APP_AUTH_SECRET=$APP_AUTH_SECRET" >> inputs.env
                      [ -n "$APP_MAIN_SECRET" ] && echo  "export APP_MAIN_SECRET=$APP_MAIN_SECRET" >> inputs.env
                      [ -n "$MASTER_KEY" ] && echo  "export MASTER_KEY=$MASTER_KEY" >> inputs.env
                      [ -n "$EVENT_HMAC_KEY" ] && echo  "export EVENT_HMAC_KEY=$EVENT_HMAC_KEY" >> inputs.env
                      [ -n "$RPC_HMAC_KEY" ] && echo  "export RPC_HMAC_KEY=$RPC_HMAC_KEY" >> inputs.env
                      [ -n "$EXPOSURE_HMAC_KEY" ] && echo  "export EXPOSURE_HMAC_KEY=$EXPOSURE_HMAC_KEY" >> inputs.env
                      [ -n "$INDEXER_HMAC_KEY" ] && echo  "export INDEXER_HMAC_KEY=$INDEXER_HMAC_KEY" >> inputs.env
                      echo  "export EXTERNAL_PGSQL_SVC_ENABLED=$EXTERNAL_PGSQL_SVC_ENABLED" >> inputs.env
                      echo  "export EXTERNAL_REDIS_SVC_ENABLED=$EXTERNAL_REDIS_SVC_ENABLED" >> inputs.env
                      [ -n "$REDIS_SSL" ] && echo  "export REDIS_SSL=$REDIS_SSL" >> inputs.env
                      [ -n "$REDIS_VER" ] && echo  "export REDIS_VER=$REDIS_VER" >> inputs.env
                      [ -n "$PG_VECTOR_VERSION" ] && echo  "export PG_VECTOR_VERSION=$PG_VECTOR_VERSION" >> inputs.env
                      [ -n "$PG_CUSTOM_CONFIG_ENABLED" ] && echo  "export PG_CUSTOM_CONFIG_ENABLED=$PG_CUSTOM_CONFIG_ENABLED" >> inputs.env
                      [ -n "$GRAFANA_MCP_ENABLED" ] && echo  "export GRAFANA_MCP_ENABLED=$GRAFANA_MCP_ENABLED" >> inputs.env
                      if [ "$GRAFANA_MCP_ENABLED" = "true" ]; then
                        printf 'export GRAFANA_URL=%q\n' "$GRAFANA_URL" >> inputs.env
                        printf 'export GRAFANA_SERVICE_ACCOUNT_TOKEN=%q\n' "$GRAFANA_SERVICE_ACCOUNT_TOKEN" >> inputs.env
                        printf 'export GRAFANA_ORG_ID=%q\n' "$GRAFANA_ORG_ID" >> inputs.env
                        printf 'export GRAFANA_EXTRA_HEADERS=%q\n' "$GRAFANA_EXTRA_HEADERS" >> inputs.env
                        printf 'export GRAFANA_MCP_TRANSPORT=%q\n' "$GRAFANA_MCP_TRANSPORT" >> inputs.env
                        printf 'export GRAFANA_MCP_ADDRESS=%q\n' "$GRAFANA_MCP_ADDRESS" >> inputs.env
                        printf 'export GRAFANA_MCP_ENDPOINT_PATH=%q\n' "$GRAFANA_MCP_ENDPOINT_PATH" >> inputs.env
                        printf 'export GRAFANA_MCP_ALLOWED_HOSTS=%q\n' "$GRAFANA_MCP_ALLOWED_HOSTS" >> inputs.env
                        printf 'export GRAFANA_MCP_LOG_LEVEL=%q\n' "$GRAFANA_MCP_LOG_LEVEL" >> inputs.env
                        printf 'export GRAFANA_MCP_ALLOWED_ORIGINS=%q\n' "$GRAFANA_MCP_ALLOWED_ORIGINS" >> inputs.env
                        printf 'export GRAFANA_MCP_DISABLE_WRITE=%q\n' "$GRAFANA_MCP_DISABLE_WRITE" >> inputs.env
                      fi
                      [ -n "$ADO_MCP_ENABLED" ] && echo "export ADO_MCP_ENABLED=$ADO_MCP_ENABLED" >> inputs.env
                      if [ "$ADO_MCP_ENABLED" = "true" ]; then
                        printf 'export ADO_MCP_IMAGE=%q\n' "$ADO_MCP_IMAGE" >> inputs.env
                        printf 'export ADO_MCP_ORGANIZATION=%q\n' "$ADO_MCP_ORGANIZATION" >> inputs.env
                        printf 'export ADO_MCP_AUTHENTICATION=%q\n' "$ADO_MCP_AUTHENTICATION" >> inputs.env
                        printf 'export ADO_MCP_TRANSPORT=%q\n' "$ADO_MCP_TRANSPORT" >> inputs.env
                        printf 'export ADO_MCP_HOST=%q\n' "$ADO_MCP_HOST" >> inputs.env
                        printf 'export ADO_MCP_PORT=%q\n' "$ADO_MCP_PORT" >> inputs.env
                        printf 'export ADO_MCP_ALLOWED_HOSTS=%q\n' "$ADO_MCP_ALLOWED_HOSTS" >> inputs.env
                        printf 'export ADO_MCP_PERSONAL_ACCESS_TOKEN=%q\n' "$ADO_MCP_PERSONAL_ACCESS_TOKEN" >> inputs.env
                        printf 'export TOOLS_ENABLED=%q\n' "$TOOLS_ENABLED" >> inputs.env
                        printf 'export ADO_MCP_LEGACY_API_KEY_ENABLED=%q\n' "$ADO_MCP_LEGACY_API_KEY_ENABLED" >> inputs.env
                        if [ "$ADO_MCP_LEGACY_API_KEY_ENABLED" = "true" ]; then
                          printf 'export ADO_MCP_API_KEY=%q\n' "$ADO_MCP_API_KEY" >> inputs.env
                        fi
                        printf 'export ADO_MCP_MULTIPLE_API_KEYS_ENABLED=%q\n' "$ADO_MCP_MULTIPLE_API_KEYS_ENABLED" >> inputs.env
                        if [ "$ADO_MCP_MULTIPLE_API_KEYS_ENABLED" = "true" ]; then
                          printf 'export ADO_MCP_API_KEYS=%q\n' "$ADO_MCP_API_KEYS" >> inputs.env
                        fi
                      fi
                      ;;
     *)   printf "skipping.....";;
   esac


printf "\nDone. Your inputs have been saved to inputs.env.\n"

# --- Deploy ---
if [ "$QUICK" = "true" ]; then _go=yes; else
  printf "\nStart deployment now (make init/apply/up)? yes/no [default: yes]: "; IFS= read -r _go
fi
case "$(printf "%s" "${_go:-yes}" | tr '[:upper:]' '[:lower:]')" in
  y|yes) make init && make apply && make up &&
         printf "\nELITEA is starting: http://%s:%s  (admin password is in inputs.env)\n" "$APP_HOST" "$HTTP_HOST_PORT"
         [ "$APP_HOST" = "localhost" ] || printf "NOTE: APP_HOST=%s must match the address in the browser. Another IP/DNS? Re-run: APP_HOST=<name> bash start.sh\n" "$APP_HOST"
         [ -n "$PORT_NOTE" ] && [ "$HTTP_HOST_PORT" = "$DEFAULT_HTTP_PORT" ] && printf "NOTE: %s\n" "$PORT_NOTE" ;;
  *) printf "Later run: source inputs.env && make init apply up\n"
     [ -n "$PORT_NOTE" ] && printf "NOTE: %s\n" "$PORT_NOTE" ;;
esac
