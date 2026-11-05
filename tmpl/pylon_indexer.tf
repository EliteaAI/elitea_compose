resource "local_file" "pylon_indexer" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_indexer/pylon_indexer.yml.tpl",
    {
      PROXY_ENABLED      = var.PROXY_ENABLED
      ELITEA_RELEASE     = var.ELITEA_RELEASE
      ELITEA_REMOTE_REPO = var.ELITEA_REMOTE_REPO
      CA_ENABLED         = var.CA_ENABLED
    }
  )
  filename = "../pylon_indexer/pylon.yml"
}

resource "local_file" "bootstrap_pylon_indexer" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_indexer/bootstrap_indexer.yml.tpl",
    {
      ELITEA_REMOTE_REPO = var.ELITEA_REMOTE_REPO
      PROXY_ENABLED      = var.PROXY_ENABLED
      ELITEA_RELEASE     = var.ELITEA_RELEASE
      MESH_ENABLED       = var.MESH_ENABLED
      AUTOCREATE_DB      = var.AUTOCREATE_DB
    }
  )
  filename = "../pylon_indexer/configs/bootstrap.yml"
}

resource "local_file" "pylon_indexer_worker" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_indexer/indexer_worker.yml.tpl",
    {
      PROXY_ENABLED      = var.PROXY_ENABLED
      ELITEA_RELEASE     = var.ELITEA_RELEASE
      ELITEA_REMOTE_REPO = var.ELITEA_REMOTE_REPO
      CA_ENABLED         = var.CA_ENABLED
      PG_CLOUD     = var.PG_CLOUD
    }
  )
  filename = "../pylon_indexer/configs/indexer_worker.yml"
}

resource "local_file" "pylon_indexer_litellm_engine" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_indexer/runtime_engine_litellm.yml.tpl",
    {
    }
  )
  filename = "../pylon_indexer/configs/runtime_engine_litellm.yml"
}

resource "local_file" "pylon_indexer_worker_core" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_indexer/worker_core.yml.tpl",
    {
      EVENT_RND = random_integer.event_queue_rnd.result
    }
  )
  filename = "../pylon_indexer/configs/worker_core.yml"
}

resource "local_file" "indexer_tracing" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_indexer/tracing.yml.tpl",
    {
      EVENT_RND             = random_integer.event_queue_rnd.result
      TRACING_ENABLED       = var.TRACING_ENABLED
      INTERNAL_OTPL_ENABLED = var.INTERNAL_OTPL_ENABLED
    }
  )
  filename = "../pylon_indexer/configs/tracing.yml"
}
