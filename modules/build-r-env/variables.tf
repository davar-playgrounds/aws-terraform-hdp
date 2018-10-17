variable "depends_on" {
  default = ""
}

variable "cluster_type" {
  default =  "r-server"
}

variable "path_in_consul_aws" {
  default   = "test/master/aws/test-instance/single/"
}

variable "consul_server" {
  default   = "127.0.0.1"
}

variable "consul_port" {
  default   = "8500"
}

variable "datacenter" {
  default   = "dc1"
}

data "consul_keys" "app" {
  key {
    name    = "public_ip"
    path    = "${var.path_in_consul_aws}${var.cluster_type}/public_ip"
  }
  key {
    name    = "public_dns"
    path    = "${var.path_in_consul_aws}${var.cluster_type}/public_dns"
  }
}
