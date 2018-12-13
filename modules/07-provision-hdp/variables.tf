variable "cluster_type" {}

variable "path_in_consul" {
  default   = "test/master/aws/test-instance"
}

variable "path_in_consul_hdp" {
  default   = "test/master/aws/"
}

variable "hdp_spec" {
  default = "/output/hdp-cluster-config.yml"
}

data "consul_keys" "hdp" {
  key {
    name = "hdp_cluster_name"
    path = "${var.path_in_consul_hdp}${var.cluster_type}/cluster_name"
  }

  key {
    name = "ambari_version"
    path = "${var.path_in_consul_hdp}${var.cluster_type}/ambari_version"
  }

  key {
    name = "hdp_version"
    path = "${var.path_in_consul_hdp}${var.cluster_type}/hdp_version"
  }

  key {
    name = "hdp_build_number"
    path = "${var.path_in_consul_hdp}${var.cluster_type}/hdp_build_number"
  }

  key {
    name = "ambari_services"
    path = "${var.path_in_consul_hdp}${var.cluster_type}/ambari_services"
  }

  key {
    name = "master_clients"
    path = "${var.path_in_consul_hdp}${var.cluster_type}/master_clients"
  }

  key {
    name = "master_services"
    path = "${var.path_in_consul_hdp}${var.cluster_type}/master_services"
  }

  key {
    name = "slave_clients"
    path = "${var.path_in_consul_hdp}${var.cluster_type}/slave_clients"
  }

  key {
    name = "slave_services"
    path = "${var.path_in_consul_hdp}${var.cluster_type}/slave_services"
  }
}
