resource "local_file" "pylon_inventory" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_inventory/pylon_inventory.yml.tpl",
    {
      PROXY_ENABLED      = var.PROXY_ENABLED
      ELITEA_RELEASE     = var.ELITEA_RELEASE
      ELITEA_REMOTE_REPO = var.ELITEA_REMOTE_REPO
      CA_ENABLED         = var.CA_ENABLED
      EVENT_RND          = random_integer.event_queue_rnd.result
    }
  )
  filename = "../pylon_inventory/pylon.yml"
}

resource "local_file" "bootstrap_pylon_inventory" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_inventory/bootstrap_inventory.yml.tpl",
    {
      ELITEA_REMOTE_REPO = var.ELITEA_REMOTE_REPO
      PROXY_ENABLED      = var.PROXY_ENABLED
      ELITEA_RELEASE     = var.ELITEA_RELEASE
      MESH_ENABLED       = var.MESH_ENABLED
    }
  )
  filename = "../pylon_inventory/configs/bootstrap.yml"
}

resource "local_file" "inventory" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_inventory/inventory_plugin.yml.tpl",
    {
    }
  )
  filename = "../pylon_inventory/configs/inventory_plugin.yml"
}
