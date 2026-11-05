resource "local_file" "pylon_deepwiki" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_deepwiki/pylon_deepwiki.yml.tpl",
    {
      PROXY_ENABLED      = var.PROXY_ENABLED
      ELITEA_RELEASE     = var.ELITEA_RELEASE
      ELITEA_REMOTE_REPO = var.ELITEA_REMOTE_REPO
      CA_ENABLED         = var.CA_ENABLED
      EVENT_RND          = random_integer.event_queue_rnd.result
    }
  )
  filename = "../pylon_deepwiki/pylon.yml"
}

resource "local_file" "bootstrap_pylon_deepwiki" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_deepwiki/bootstrap_deepwiki.yml.tpl",
    {
      ELITEA_REMOTE_REPO = var.ELITEA_REMOTE_REPO
      PROXY_ENABLED      = var.PROXY_ENABLED
      ELITEA_RELEASE     = var.ELITEA_RELEASE
      MESH_ENABLED       = var.MESH_ENABLED
    }
  )
  filename = "../pylon_deepwiki/configs/bootstrap.yml"
}

resource "local_file" "deepwiki" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_deepwiki/deepwiki_plugin.yml.tpl",
    {
      EVENT_RND       = random_integer.event_queue_rnd.result
      TRACING_ENABLED = var.TRACING_ENABLED
    }
  )
  filename = "../pylon_deepwiki/configs/deepwiki_plugin.yml"
}
