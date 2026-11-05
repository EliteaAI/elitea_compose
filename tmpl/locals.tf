locals {

  PYLON_REG_LOCAL = contains(["1.2.26", "1.2.25", "1.2.24"], var.PYLON_VER) ? var.PYLON_REGISTRY : "ghcr.io/eliteaai/pylon"

}
