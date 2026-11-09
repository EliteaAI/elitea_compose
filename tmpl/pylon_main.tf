resource "local_file" "pylon_main_admin" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_main/admin.yml.tpl",
    {
      AWS_REDIS_ENABLED = var.AWS_REDIS
    }
  )
  filename = "../pylon_main/configs/admin.yml"
}

resource "local_file" "pylon_main_auth" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_main/auth.yml.tpl",
    {
      AWS_REDIS_ENABLED = var.AWS_REDIS
    }
  )
  filename = "../pylon_main/configs/auth.yml"
}

resource "local_file" "bootstrap_pylon_main" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_main/bootstrap_main.yml.tpl",
    {
      ELITEA_REMOTE_REPO = var.ELITEA_REMOTE_REPO
      GITHUB_AUTH        = var.GITHUB_AUTH
      PROXY_ENABLED      = var.PROXY_ENABLED
      ELITEA_RELEASE     = var.ELITEA_RELEASE
      MESH_ENABLED       = var.MESH_ENABLED
      AUTOCREATE_DB      = var.AUTOCREATE_DB
    }
  )
  filename = "../pylon_main/configs/bootstrap.yml"
}


resource "local_file" "pylon_main_elitea_core" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_main/elitea_core.yml.tpl",
    {
      EVENT_RND          = random_integer.event_queue_rnd.result
      ALLOWED_DOMAINS    = var.ALLOWED_DOMAINS
      SELF_HTTPS_ENABLED = var.SELF_HTTPS
    }
  )
  filename = "../pylon_main/configs/elitea_core.yml"
}

resource "local_file" "pylon_main_logging_hub" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_main/logging_hub.yml.tpl",
    {
      EVENT_RND = random_integer.event_queue_rnd.result
    }
  )
  filename = "../pylon_main/configs/logging_hub.yml"
}

resource "local_file" "pylon_main" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_main/pylon_main.yml.tpl",
    {
      SELF_HTTPS_ENABLED      = var.SELF_HTTPS
      PROXY_ENABLED           = var.PROXY_ENABLED
      ELITEA_RELEASE          = var.ELITEA_RELEASE
      ELITEA_REMOTE_REPO      = var.ELITEA_REMOTE_REPO
      CA_ENABLED              = var.CA_ENABLED
      EVENT_RND               = random_integer.event_queue_rnd.result
      SSO_EXPIRATION_OVERRIDE = var.SSO_EXPIRATION_OVERRIDE
    }
  )
  filename = "../pylon_main/pylon.yml"
}

resource "local_file" "pylon_main_shared" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_main/shared.yml.tpl",
    {
      AWS_REDIS_ENABLED = var.AWS_REDIS
    }
  )
  filename = "../pylon_main/configs/shared.yml"
}

resource "local_file" "worker_client" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_main/worker_client.yml.tpl",
    {
      EVENT_RND = random_integer.event_queue_rnd.result
    }
  )
  filename = "../pylon_main/configs/worker_client.yml"
}

resource "local_file" "main_tracing" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_main/tracing.yml.tpl",
    {
      EVENT_RND             = random_integer.event_queue_rnd.result
      TRACING_ENABLED       = var.TRACING_ENABLED
      INTERNAL_OTPL_ENABLED = var.INTERNAL_OTPL_ENABLED
    }
  )
  filename = "../pylon_main/configs/tracing.yml"
}
