/*

#######################
### hdp config file ###
#######################
# second file that is rendered is the cluster configuration file
# there is one block in template - variable blueprint-dynamic - which depends on whether
# it is a single node or a multi node cluster. That block defines which services and
# clients should be installed on which host groups
# The idea is to make this dynamic to avoid updating two templates
# To make this work, interim files are used for that block

# generate the single blueprint_dynamic block of the hdp-config file
data "template_file" "generate_blueprint_dynamic_single" {
  count = "${local.type == "single" ? 1 : 0}"
  template = "${file("${path.module}/resources/templates/blueprint_dynamic_single.tmpl")}"
  vars {
    master_clients = "${local.master_clients}"
    master_services = "${local.master_services}"
  }
}

# generate the block with n_namenodes and their clients and services
# in case of HA there will be two host_group block - 01 and 02
data "template_file" "generate_blueprint_master_block" {
  count = "${local.type == "cluster" ? local.no_namenodes : 0}"
  template = "${file("${path.module}/resources/templates/blueprint_dynamic_host_group_master.tmpl")}"

  vars {
    host_group_name = "- host_group: \"hdp-master-0${count.index + 1}\""
    clients = "clients: ${local.master_clients}"
    services_text = "services:"
    services = "${local.master_services}\n"
  }
}

# generate the cluster blueprint_dynamic block of the hdp-config file
data "template_file" "generate_blueprint_dynamic_cluster" {
  count = "${local.type == "cluster" ? 1 : 0}"
  template = "${file("${path.module}/resources/templates/blueprint_dynamic_cluster.tmpl")}"
  vars {
    ambari_services = "${local.ambari_services}"
    host_group_master = "${join("",data.template_file.generate_blueprint_master_block.*.rendered)}"
    slave_clients = "${local.slave_clients}"
    slave_services = "${local.slave_services}"
  }
}

*/
### prepare hdp config file
data "template_file" "hdp_config" {
  template = "${file("${path.module}/resources/templates/${local.hdp_config_tmpl}")}"

  vars {
    clustername = "${local.clustername}"
    ambari_version = "${local.ambari_version}"
    hdp_version = "${local.hdp_version}"
    hdp_build_number = "${local.hdp_build_number}"
    database = "${local.database}"
    # the blueprint_dynamic block is built based on type is single or cluster
    blueprint_dynamic = "" #"${local.type == "single" ? join("", data.template_file.generate_blueprint_dynamic_single.*.rendered) : join("", data.template_file.generate_blueprint_dynamic_cluster.*.rendered)}"
  }
}

# render hdp config file
resource "local_file" "hdp_config_rendered" {
  depends_on = ["module.provision_hdp"]

  content  = "${data.template_file.hdp_config.rendered}"
  filename = "${local.workdir}/hdp-config.yml"
}
