#########################
### ansible host file ###
#########################
# the host file groups servers to a specific host group. the names of host groups
# have to match the names in the cluster configuration file.

# the idea is to render a file called ansible-hosts whether it is a single or multi node cluster

### SINGLE ###
# single node cluster will have only one line with one server
# the template file is populated with variables, no interim file is used

# populate the template file with variables
data "template_file" "ansible_inventory_single" {
  count = "${local.type == "single" ? 1 : 0}"
  template = "${file("${path.module}/resources/templates/ansible_inventory_single.yml.tmpl")}"
  vars {
    ansible_hdp_master_name = "${local.ambari_dns}"
    ansible_hdp_master_hosts = "${local.ambari_ips}"
  }
}

### CLUSTER ###
# the cluster has one server (first one) dedicated for cluster management -
# Ambari services are running on it, Postgres metastore and some Hadoop related
# services that cannot be made into HA are running on it
# Cluster design is inspired by the examples from the ansible-hortonworks repository

# generate a datanode file - one datanode per line
# this file is used later in the process to render the ansible-hosts file
data "template_file" "generate_datanode_hostname_cluster" {
  count = "${local.type == "cluster" ? local.no_datanodes : 0}" # workaround
  template = "${file("${path.module}/resources/templates/datanode_hostname.tmpl")}"
  vars {
    datanode-text = "${element(local.datanodes_ips, count.index)} ansible_host=${element(local.datanodes_dns, count.index)} ansible_user=centos ansible_ssh_private_key_file=\"/home/centos/.ssh/id_rsa\""
  }
}

data "template_file" "generate_namenode_hostname_cluster" {
  count = "${local.type == "cluster" ? local.no_namenodes : 0}"
  template = "${file("${path.module}/resources/templates/namenode_hostname.tmpl")}"
  vars {
    host-group-name = "[hdp-master-0${count.index + 1}]"
    namenode-text = "${element(local.namenodes_ips, count.index)} ansible_host=${element(local.namenodes_dns, count.index)} ansible_user=centos ansible_ssh_private_key_file=\"/home/centos/.ssh/id_rsa\""
  }
}

# ansible-hosts file for cluster Hadoop architecture is rendered here
# populate the cluster template file
data "template_file" "ansible_inventory_cluster" {
  count = "${local.type == "cluster" ? 1 : 0}"
  template = "${file("${path.module}/resources/templates/ansible_inventory_cluster.yml.tmpl")}"
  vars {
    ambari-services-title = "[ambari-services]"
    ambari-ansible-text = "${local.ambari_ips} ambari_host=${local.ambari_dns} ansible_user=centos ansible_ssh_private_key_file=\"/home/centos/.ssh/id_rsa\""
    namenode-ansible-text = "${join("",data.template_file.generate_namenode_hostname_cluster.*.rendered)}"
    hdp-worker-title = "[hdp-worker]"
    datanode-ansible-text = "${join("",data.template_file.generate_datanode_hostname_cluster.*.rendered)}"
  }
}

# create the yaml file based on template and the input values
resource "local_file" "ansible_inventory_single_render" {
  count = "${local.type == "single" ? 1 : 0}"
  content  = "${data.template_file.ansible_inventory_single.rendered}"
  filename = "${local.workdir}/ansible-hosts"
}

resource "local_file" "ansible_inventory_cluster_render" {
  count = "${local.type == "cluster" ? 1 : 0}"
  content  = "${data.template_file.ansible_inventory_cluster.rendered}"
  filename = "${local.workdir}/ansible-hosts"
}
