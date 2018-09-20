variable "cluster_type" {}

variable "path_in_consul_aws" {
  default   = "test/master/aws/test-instance"
}

variable "path_in_consul_hdp" {
  default   = "test/master/aws/hdp-"
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
    path    = "${var.path_in_consul_aws}/region"
  }
  key {
    name    = "ami"
    path    = "${var.path_in_consul_aws}/ami_id"
  }
  key {
    name    = "Name"
    path    = "${var.path_in_consul_aws}/tags/Name"
  }
  key {
    name    = "security_group"
    path    = "${var.path_in_consul_aws}/default_security_group_id"
  }
  key {
    name    = "availability_zone"
    path    = "${var.path_in_consul_aws}/availability_zone"
  }
  key {
    name    = "subnet_id"
    path    = "${var.path_in_consul_aws}/subnet_id"
  }
  key {
    name    = "no_instances"
    path    = "${var.path_in_consul_hdp}${var.cluster_type}/no_instances"
  }
  key {
    name    = "instance_type"
    path    = "${var.path_in_consul_hdp}${var.cluster_type}/instance_type"
  }
}
