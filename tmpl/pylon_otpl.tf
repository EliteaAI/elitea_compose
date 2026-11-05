resource "local_file" "pylon_otpl" {
  content = templatefile(
    "${path.module}/tftemplates/pylon_otpl/config.yml.tpl",
    {
    }
  )
  filename = "../pylon_otpl/configs/config.yml"
}
