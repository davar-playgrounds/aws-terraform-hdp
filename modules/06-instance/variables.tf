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

data "consul_keys" "app" {
  key {
    name    = "region"
    path    = "${var.path_in_consul}/region"
  }
  key {
    name    = "ami"
    path    = "${var.path_in_consul}/ami_id"
  }
  key {
    name    = "instance_type"
    path    = "${var.path_in_consul}/instance_type"
  }
  key {
    name    = "Name"
    path    = "${var.path_in_consul}/tags/Name"
  }
  key {
    name    = "security_group"
    path    = "${var.path_in_consul}/default_security_group_id"
  }
  key {
    name    = "availability_zone"
    path    = "${var.path_in_consul}/availability_zone"
  }
  key {
    name    = "subnet_id"
    path    = "${var.path_in_consul}/subnet_id"
  }
  key {
    name    = "no_instances"
    path    = "${var.path_in_consul}/no_instances"
    default = "2"
  }
}
