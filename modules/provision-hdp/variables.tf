locals {
  workdir = "${path.cwd}/output"
}

variable "path_in_consul" {
  default   = "test/master/aws/test-instance"
}

data "consul_keys" "app" {
  key {
    name    = "public_dns_namenode"
    path    = "${var.path_in_consul}/public_dns_namenode"
  }
  key {
    name    = "public_dns_datanode"
    path    = "${var.path_in_consul}/public_dns_datanode"
  }
}
