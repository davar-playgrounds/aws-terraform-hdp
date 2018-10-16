module r_server {
  source             = "../spectrum-scale"
  cluster_type       = "r-server"
}

resource "null_resource" "ansible_galaxy" {
  # Get ansible role from galaxy
  provisioner "local-exec" {
    command = "ansible-galaxy install debops.rstudio_server"
  }
}
