resource "local_file" "pylon_imagegen" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_imagegen/pylon_imagegen.yml.tpl",
    {
      PROXY_ENABLED      = var.PROXY_ENABLED
      ELITEA_RELEASE     = var.ELITEA_RELEASE
      ELITEA_REMOTE_REPO = var.ELITEA_REMOTE_REPO
      CA_ENABLED         = var.CA_ENABLED
      EVENT_RND          = random_integer.event_queue_rnd.result
    }
  )
  filename = "../pylon_imagegen/pylon.yml"
}

resource "local_file" "bootstrap_pylon_imagegen" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_imagegen/bootstrap_imagegen.yml.tpl",
    {
      ELITEA_REMOTE_REPO = var.ELITEA_REMOTE_REPO
      GITHUB_AUTH        = var.GITHUB_AUTH
      PROXY_ENABLED      = var.PROXY_ENABLED
      ELITEA_RELEASE     = var.ELITEA_RELEASE
      MESH_ENABLED       = var.MESH_ENABLED
    }
  )
  filename = "../pylon_imagegen/configs/bootstrap.yml"
}

resource "local_file" "imagegen" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_imagegen/imagegen.yml.tpl",
    {
      EVENT_RND       = random_integer.event_queue_rnd.result
      TRACING_ENABLED = var.TRACING_ENABLED
    }
  )
  filename = "../pylon_imagegen/configs/imagegen.yml"
}
