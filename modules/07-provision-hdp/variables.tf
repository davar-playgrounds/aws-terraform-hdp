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

data "consul_keys" "app" {
  # ambari
  key {
    #name    = "public_dns_ambari"
    name    = "public_dns"
    #path    = "${var.path_in_consul}/public_dns_ambari"
    path    = "${var.path_in_consul}/public_dns"
  }
  key {
    #name    = "public_ip_ambari"
    #path    = "${var.path_in_consul}/public_ip_ambari"
    name    = "public_ips"
    path    = "${var.path_in_consul}/public_ips"
  }
  # namenode
  #key {
    #name    = "public_dns_namenode"
    #path    = "${var.path_in_consul}/public_dns_namenode"
  #}
#  key {
#    name    = "public_ip_namenode"
#    path    = "${var.path_in_consul}/public_ip_namenode"
#  }
  # datanode
  #key {
  #  name    = "public_dns_datanode"
  #  path    = "${var.path_in_consul}/public_dns_datanode"
  #}
  #key {
  #  name    = "public_ip_datanode"
  #  path    = "${var.path_in_consul}/public_ip_datanode"
  #}
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
    name = "master-clients"
    path = "${var.path_in_consul_hdp}${var.cluster_type}/master-clients"
  }

  key {
    name = "master-services"
    path = "${var.path_in_consul_hdp}${var.cluster_type}/master-services"
  }

  key {
    name = "slave-services"
    path = "${var.path_in_consul_hdp}${var.cluster_type}/slave-services"
  }
}
