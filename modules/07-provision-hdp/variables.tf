locals {
  workdir = "${path.cwd}"
}

variable "path_in_consul" {
  default   = "test/master/aws/test-instance"
}

/*
variable "hdp_spec" {
  default = "/resources/hdp-cluster-minimal.yml"
}*/

data "consul_keys" "app" {
  key {
    name    = "public_dns_namenode"
    path    = "${var.path_in_consul}/public_dns_namenode"
  }
  key {
    name    = "public_dns_datanode"
    path    = "${var.path_in_consul}/public_dns_datanode"
  }
  key {
    name    = "hdp_spec"
    path    = "${var.path_in_consul}/aaa-hdp3-spec"
    default = "/resources/hdp-cluster-minimal.yml"
  }
}
