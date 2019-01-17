variable "cluster_type" {}

variable "path_in_consul" {
  default   = "test/master/aws/test-instance"
}

variable "path_in_consul_hdp" {
  default   = "test/master/aws/"
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
    name    = "path_to_generated_aws_properties"
    path    = "${var.path_in_consul}/path_to_generated_aws_properties"
  }
  key {
    name    = "ami"
    path    = "${var.path_in_consul}/ami_id"
  }
  key {
    name    = "instance_type"
    path    = "${var.path_in_consul_hdp}${var.cluster_type}/instance_type"
  }
  key {
    name    = "type"
    path    = "${var.path_in_consul_hdp}${var.cluster_type}/type"
    #description = "type of cluster: single or cluster"
  }
  key {
    name    = "no_namenodes"
    path    = "${var.path_in_consul_hdp}${var.cluster_type}/no_namenodes"
    #description = "Number of namenodes in cluster: 1 or 2"
    default = "2"
  }
  key {
    name    = "no_datanodes"
    path    = "${var.path_in_consul_hdp}${var.cluster_type}/no_datanodes"
    #description = "Number of datanodes "
    default = "0"
  }
}

data "consul_keys" "aws" {
  key {
    name    = "security_group"
    path    = "${data.consul_keys.app.var.path_to_generated_aws_properties}/default_security_group_id"
  }
  key {
    name    = "availability_zone"
    path    = "${data.consul_keys.app.var.path_to_generated_aws_properties}/availability_zone"
  }
  key {
    name    = "subnet_id"
    path    = "${data.consul_keys.app.var.path_to_generated_aws_properties}/subnet_id"
  }

}
