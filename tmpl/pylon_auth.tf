resource "local_file" "pylon_auth" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_auth/pylon_auth.yml.tpl",
    {
      PROXY_ENABLED      = var.PROXY_ENABLED
      ELITEA_RELEASE     = var.ELITEA_RELEASE
      ELITEA_REMOTE_REPO = var.ELITEA_REMOTE_REPO
      CA_ENABLED         = var.CA_ENABLED
      EVENT_RND          = random_integer.event_queue_rnd.result
    }
  )
  filename = "../pylon_auth/pylon.yml"
}

resource "local_file" "auth_core" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_auth/auth_core.yml.tpl",
    {
      SSO_MODE = var.SSO_MODE
    }
  )
  filename = "../pylon_auth/configs/auth_core.yml"
}

resource "local_file" "auth_oidc" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_auth/auth_oidc.yml.tpl",
    {
      SSO_MODE                    = var.SSO_MODE
      OIDC_AUTHORIZATION_ENDPOINT = var.OIDC_AUTHORIZATION_ENDPOINT
      OIDC_CLIENT_ID              = var.OIDC_CLIENT_ID
      OIDC_CLIENT_SECRET          = var.OIDC_CLIENT_SECRET
      OIDC_END_SESSION_ENDPOINT   = var.OIDC_END_SESSION_ENDPOINT
      OIDC_METADATA_ENDPOINT      = var.OIDC_METADATA_ENDPOINT
      OIDC_TOKEN_ENDPOINT         = var.OIDC_TOKEN_ENDPOINT
      OIDC_URL_MODE               = var.OIDC_URL_MODE
      OIDC_USERINFO_ENDPOINT      = var.OIDC_USERINFO_ENDPOINT
      SSO_EXPIRATION_OVERRIDE     = var.SSO_EXPIRATION_OVERRIDE
    }
  )
  filename = "../pylon_auth/configs/auth_oidc.yml"
}

resource "local_file" "auth_saml" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_auth/auth_saml.yml.tpl",
    {
      SSO_MODE                = var.SSO_MODE
      SAML_AUTHN_DESTINATION  = var.SAML_AUTHN_DESTINATION
      SAML_LOGOUT_DESTINATION = var.SAML_LOGOUT_DESTINATION
      SAML_ISSUER             = var.SAML_ISSUER
      SAML_SP_KEY             = var.SAML_SP_KEY
      SAML_SP_CERT            = var.SAML_SP_CERT
      SAML_IDP_METADATA       = var.SAML_IDP_METADATA
      SAML_IDP_CERT           = var.SAML_IDP_CERT
      SSO_EXPIRATION_OVERRIDE = var.SSO_EXPIRATION_OVERRIDE
    }
  )
  filename = "../pylon_auth/configs/auth_saml.yml"
}

resource "local_file" "auth_init" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_auth/auth_init.yml.tpl",
    {
    }
  )
  filename = "../pylon_auth/configs/auth_init.yml"
}

resource "local_file" "auth_form" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_auth/auth_form.yml.tpl",
    {
    }
  )
  filename = "../pylon_auth/configs/auth_form.yml"
}

resource "local_file" "bootstrap_pylon_auth" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_auth/bootstrap_auth.yml.tpl",
    {
      ELITEA_REMOTE_REPO = var.ELITEA_REMOTE_REPO
      PROXY_ENABLED      = var.PROXY_ENABLED
      ELITEA_RELEASE     = var.ELITEA_RELEASE
      MESH_ENABLED       = var.MESH_ENABLED
    }
  )
  filename = "../pylon_auth/configs/bootstrap.yml"
}

resource "local_file" "auth_tracing" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_auth/tracing.yml.tpl",
    {
      EVENT_RND             = random_integer.event_queue_rnd.result
      TRACING_ENABLED       = var.TRACING_ENABLED
      INTERNAL_OTPL_ENABLED = var.INTERNAL_OTPL_ENABLED
    }
  )
  filename = "../pylon_auth/configs/tracing.yml"
}
