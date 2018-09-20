locals {
  workdir = "${path.cwd}"
}

variable "path_in_consul" {
  default   = "test/master/aws/test-instance"
}

variable "path_in_consul_hdp" {
  default   = "test/master/aws/hdp"
}


variable "hdp_spec" {
  default = ""
}

data "consul_keys" "app" {
  # ambari
  key {
    name    = "public_dns_ambari"
    path    = "${var.path_in_consul}/public_dns_ambari"
  }
  key {
    name    = "public_ip_ambari"
    path    = "${var.path_in_consul}/public_ip_ambari"
  }
  # namenode
  key {
    name    = "public_dns_namenode"
    path    = "${var.path_in_consul}/public_dns_namenode"
  }
  key {
    name    = "public_ip_namenode"
    path    = "${var.path_in_consul}/public_ip_namenode"
  }
  # datanode
  key {
    name    = "public_dns_datanode"
    path    = "${var.path_in_consul}/public_dns_datanode"
  }
  key {
    name    = "public_ip_datanode"
    path    = "${var.path_in_consul}/public_ip_datanode"
  }
}

data "consul_keys" "hdp" {
  key {
    name = "hdp_cluster_name"
    path = "${var.path_in_consul_hdp}/cluster_name"
  }

  key {
    name = "master-clients"
    path = "${var.path_in_consul_hdp}/master-clients"
  }

  key {
    name = "master-services"
    path = "${var.path_in_consul_hdp}/master-services"
  }
}
