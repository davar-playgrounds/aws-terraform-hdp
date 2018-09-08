variable "path_in_consul" {
  default   = "test/master/aws/test-instance"
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
variable "cidr_block" {
  default = "10.0.0.0/24"
}

variable "igw_name" {
  default = "Terraform IGW"
}

data "consul_keys" "app" {
  key {
    name    = "region"
    path    = "${var.path_in_consul}/region"
  }
  key {
    name    = "vpc_id"
    path    = "${var.path_in_consul}/vpc_id"
  }
}
