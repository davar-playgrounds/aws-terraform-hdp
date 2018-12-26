module "provision_hdp" {
  source             = "../06-instance"
  cluster_type       = "${var.cluster_type}"
}

# all variables used in the script are in locals block
locals {

  workdir="${path.cwd}/output/hdp-server/${local.clustername}"

  ## all DNS and IP needed for the Hadoop cluster
  public_dns = "${module.provision_hdp.public_dns}"
  public_ips = "${module.provision_hdp.public_ip}"

  #############################
  ### variables for cluster ###
  #############################

  ## first server is ambari - no matter if single or cluster
  ambari_ips = "${local.public_ips[0]}"
  ambari_dns = "${local.public_dns[0]}"

  # indices to create the dynamic code in case single node cluster is also used
  # if a single node cluster -> indices are 0, else second server is namenode 1,
  # third server is namenode 2 and all the others are datanodes
  namenode_1_idx = "${local.no_instances == 1 ? 0 : 1}"
  namenode_2_idx = "${local.no_instances == 1 ? 0 : 2}"
  datanode_idx = "${local.no_instances == 1 ? 0 : 3}"


  # server 2 and 3 are namenodes
  # these are only used when multinode cluster, otherwise they point to first server
  namenode_1_dns = "${local.public_dns[local.namenode_1_idx]}"
  namenode_1_ips = "${local.public_ips[local.namenode_1_idx]}"
  namenode_2_dns = "${local.public_dns[local.namenode_2_idx]}"
  namenode_2_ips = "${local.public_ips[local.namenode_2_idx]}"

  ## if multinode cluster: rest of the servers are datanodes (from and including server 4)
  datanodes_dns = "${slice(local.public_dns, local.datanode_idx, length(local.public_dns))}"
  datanodes_ips = "${slice(local.public_ips, local.datanode_idx, length(local.public_ips))}"

  #########################
  ### variables for HDP ###
  #########################

  type = "${data.consul_keys.hdp.var.type}" # single, classic or skatt
  clustername = "${data.consul_keys.hdp.var.hdp_cluster_name}" # name of HDP cluster
  no_instances = "${data.consul_keys.hdp.var.no_instances}" # number of servers in cluster
  ambari_version = "${data.consul_keys.hdp.var.ambari_version}"
  hdp_version = "${data.consul_keys.hdp.var.hdp_version}"
  hdp_build_number = "${data.consul_keys.hdp.var.hdp_build_number}"
  database = "${data.consul_keys.hdp.var.database}" # database for metastore - postgres

  ambari_services = "${data.consul_keys.hdp.var.ambari_services}" # services on management server
  master_clients = "${data.consul_keys.hdp.var.master_clients}" # clients on namenodes
  master_services = "${data.consul_keys.hdp.var.master_services}" # services on namenodes
  slave_clients = "${data.consul_keys.hdp.var.slave_clients}" # clients on slaves (workers)
  slave_services = "${data.consul_keys.hdp.var.slave_services}" # services on slaves (workers)
  single = "${local.no_instances == 1 ? 1 : 0}" # is it a single node or multi?

  hdp_config_tmpl = "hdp-config.yml.tmpl" # cluster configuration template - one for all
}

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
data "template_file" "ansible_hdp_single" {
  count = "${local.type == "single" ? 1 : 0}"
  template = "${file("${path.module}/resources/templates/ansible_hdp_single.yml.tmpl")}"

  vars {
    ansible_hdp_master_name = "${local.public_dns[0]}"
    ansible_hdp_master_hosts = "${local.public_ips[0]}"
  }
}

# create the yaml file based on template and the input values
resource "local_file" "ansible_hdp_single_inventory" {
  count = "${local.type == "single" ? 1 : 0}" # execute if single
  content  = "${data.template_file.ansible_hdp_single.rendered}"
  filename = "${local.workdir}/ansible-hosts"
}
###

### CLUSTER ###
# the cluster with have one server (first one) dedicated for cluster management -
# Ambari services are running on it, Postgres metastore and some Hadoop related
# services that cannot be made into HA
# Cluster design is inspired by the examples from the ansible-hortonworks repository

# generate a datanode file - one datanode per line
# this file is used later in the process to render the ansible-hosts file
data "template_file" "generate_datanode_hostname_classic" {
  count = "${local.type == "classic" ? 1 : 0}"
  #count = "${length(local.datanodes_dns)}" # do i need this to be repeated n-times?
  template = "${file("${path.module}/resources/templates/datanode_hostname.tmpl")}"
  vars {
    datanode-text = "${element(local.datanodes_ips, count.index)} ansible_host=${element(local.datanodes_dns, count.index)} ansible_user=centos ansible_ssh_private_key_file=\"~/.ssh/id_rsa\""
  }
}

# ansible-hosts file for classic Hadoop architecture is rendered here
# populate the cluster template file
data "template_file" "ansible_inventory_classic" {
  count = "${local.type == "classic" ? 1 : 0}"
  template = "${file("${path.module}/resources/templates/ansible_hdp_cluster.yml.tmpl")}"
  vars {
    ambari-services-title = "[ambari-services]"
    ambari-ansible-text = "${local.ambari_ips} ambari_host=${local.ambari_dns} ansible_user=centos ansible_ssh_private_key_file=\"~/.ssh/id_rsa\""
    hdp-master-01-title = "[hdp-master-01]"
    namenode1-ansible-text = "${local.namenode_1_ips} ambari_host=${local.namenode_1_dns} ansible_user=centos ansible_ssh_private_key_file=\"~/.ssh/id_rsa\""
    hdp-master-02-title = "[hdp-master-02]"
    namenode2-ansible-text = "${local.namenode_2_ips} ambari_host=${local.namenode_2_dns} ansible_user=centos ansible_ssh_private_key_file=\"~/.ssh/id_rsa\""
    hdp-worker-title = "[hdp-worker]"
    datanode-ansible-text = "${join("",data.template_file.generate_datanode_hostname_classic.*.rendered)}"
  }
}
/*
# generate a temporary file with all datanodes - one datanode per line
data "template_file" "generate_datanode_hostname_skatt" {
  count = "${local.type == "skatt" ? 1 : 0}"
  #count = "${length(local.datanodes_dns)}" # do i need this to be repeated n-times?
  template = "${file("${path.module}/resources/templates/datanode_hostname.tmpl")}"

  vars {
    datanode-text = "${element(local.datanodes_ips, count.index)} ansible_host=${element(local.datanodes_dns, count.index)} ansible_user=centos ansible_ssh_private_key_file=\"~/.ssh/id_rsa\""
  }
}
*/
/*
###  ansible-hosts file for skatt Hadoop architecture is rendered here
data "template_file" "ansible_inventory_skatt" {
  count = "${local.type == "classic" ? 1 : 0}"
  template = "${file("${path.module}/resources/templates/ansible_hdp_cluster.yml.tmpl")}"
  vars {
    ambari-services-title = "[ambari-services]"
    ambari-ansible-text = "${local.ambari_ips} ambari_host=${local.ambari_dns} ansible_user=centos ansible_ssh_private_key_file=\"~/.ssh/id_rsa\""
    hdp-master-01-title = ""
    namenode1-ansible-text = ""
    hdp-master-02-title = ""
    namenode2-ansible-text = ""
    hdp-worker-title = "[hdp-master]"
    datanode-ansible-text = "${join("",data.template_file.generate_datanode_hostname.*.rendered)}"
  }
}
*/

# create the yaml file based on template and the input values
resource "local_file" "ansible_hdp_cluster_inventory" {
  count = "${1 - local.single}"

  content  = "${data.template_file.ansible_inventory_local.type.rendered}"
  filename = "${local.workdir}/ansible-hosts"
}

#######################
### hdp config file ###
#######################
# second file that is rendered is the cluster configuration file
# there is one block in template - variable blueprint-dynamic - which depends on whether
# it is a single node or a multi node cluster. That block defines which services and
# clients should be installed to which host groups
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

# generate the cluster blueprint_dynamic block of the hdp-config file
data "template_file" "generate_blueprint_dynamic_cluster" {
  count = "${local.type == "classic" ? 1 : 0}"
  template = "${file("${path.module}/resources/templates/blueprint_dynamic_cluster.tmpl")}"
  vars {
    ambari_services = "${local.ambari_services}"
    master_clients = "${local.master_clients}"
    master_services = "${local.master_services}"
    slave_clients = "${local.slave_clients}"
    slave_services = "${local.slave_services}"
  }
}

/*
### generate the skatt blueprint_dynamic block of the hdp-config file
data "template_file" "generate_blueprint_dynamic_skatt" {
  count = "${local.type == "skatt" ? 1 : 0}"
  template = "${file("${path.module}/resources/templates/blueprint_dynamic_skatt.tmpl")}"
  vars {
    ambari_services = "${local.ambari_services}"
    master_clients = "${local.master_clients}"
    master_services = "${local.master_services}"
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
    # use data.template_file depending on whether single or cluster
    blueprint_dynamic = "${join("",data.template_file.generate_blueprint_dynamic_local.type.*.rendered)}"
  }
}

# render hdp config file
resource "local_file" "hdp_config_rendered" {
  depends_on = ["module.provision_hdp"]

  content  = "${data.template_file.hdp_config.rendered}"
  filename = "${local.workdir}/hdp-config.yml"
}

##########################
### ansible-hosts and hdp-config files are rendered, below are resources for provisioning desired architecture

resource "null_resource" "passwordless_ssh" {
  depends_on = ["module.provision_hdp"]

  provisioner "local-exec" {
    command = <<-EOF
      echo "Sleeping for 20 seconds..."; sleep 20
    EOF
  }

  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible-hosts ${path.module}/resources/passwordless-ssh.yml"
  }
}

resource "null_resource" "install_python_packages" {
  depends_on = ["null_resource.passwordless_ssh"]

  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible-hosts ${path.module}/resources/install-python-packages.yml"
  }
}

resource "null_resource" "prepare_nodes" {
  depends_on = [
    "null_resource.install_python_packages",
    "local_file.ansible_hdp_cluster_inventory",
    "local_file.hdp_config_rendered"
  ]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}/hdp-config.yml ${path.module}/resources/ansible-hortonworks/playbooks/prepare_nodes.yml"
  }
}

resource "null_resource" "install_ambari" {
  depends_on = ["null_resource.prepare_nodes"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}/hdp-config.yml ${path.module}/resources/ansible-hortonworks/playbooks/install_ambari.yml"
  }
}

resource "null_resource" "configure_ambari" {
  depends_on = ["null_resource.install_ambari"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}/hdp-config.yml ${path.module}/resources/ansible-hortonworks/playbooks/configure_ambari.yml"
  }
}

## configure postgres for Ranger and Ranger KMS
resource "null_resource" "configure_postgres" {
  depends_on = ["null_resource.configure_ambari"]

  # install, configure and prepare DB objects for Ranger and RangerKMS
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = "${local.public_ips[0]}"
      user     = "centos" #"${local.template_user}"
      private_key = "${file("/home/centos/.ssh/id_rsa")}"
      #password = "${local.template_password}"
    }
    script = "${path.module}/resources/scripts/config_postgres.sh"
  }
}

resource "null_resource" "apply_blueprint" {
  depends_on = ["null_resource.configure_postgres"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}/hdp-config.yml ${path.module}/resources/ansible-hortonworks/playbooks/apply_blueprint.yml"
  }
}

resource "null_resource" "post_install" {
  depends_on = ["null_resource.apply_blueprint"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}/hdp-config.yml ${path.module}/resources/ansible-hortonworks/playbooks/post_install.yml"
  }
}
