module "provision_hdp" {
  source             = "../06-instance"
  cluster_type       = "${var.cluster_type}"
}

locals {

  workdir="${path.cwd}/output/hdp-server/${local.clustername}"

  public_dns = "${module.provision_hdp.public_dns}"
  public_ips = "${module.provision_hdp.public_ip}"

  ########################
  ## variables for cluster
  ## first server is ambari
  ambari_ips = "${local.public_ips[0]}"
  ambari_dns = "${local.public_dns[0]}" # first server is Ambari server - no matter if single or cluster
  # namenode_dns holds value of dns for the HDP cluster (Ambari server excluded)

  ## server 2 and 3 are namenodes
  namenode_1_dns = "${local.public_dns[1]}"
  namenode_1_ips = "${local.public_ips[1]}"
  namenode_2_dns = "${local.public_dns[2]}"
  namenode_2_ips = "${local.public_ips[2]}"

  ## rest of the servers are datanodes
  datanodes_dns = "${slice(local.public_dns, 3, length(local.public_dns))}"
  datanodes_ips = "${slice(local.public_ips, 3, length(local.public_ips))}"

  ## variables for HDP

  clustername = "${data.consul_keys.hdp.var.hdp_cluster_name}"
  no_instances = "${data.consul_keys.hdp.var.no_instances}"
  ambari_version = "${data.consul_keys.hdp.var.ambari_version}"
  hdp_version = "${data.consul_keys.hdp.var.hdp_version}"
  hdp_build_number = "${data.consul_keys.hdp.var.hdp_build_number}"

  ambari_services = "${data.consul_keys.hdp.var.ambari_services}"
  master_clients = "${data.consul_keys.hdp.var.master_clients}"
  master_services = "${data.consul_keys.hdp.var.master_services}"
  slave_clients = "${data.consul_keys.hdp.var.slave_clients}"
  slave_services = "${data.consul_keys.hdp.var.slave_services}"
  single = "${local.no_instances == 1 ? 1 : 0}" # is it a single node or multi?


  hdp_single_config_tmpl = "hdp-single-config.tmpl"
  hdp_cluster_config_tmpl = "hdp-cluster-config.tmpl"
  hdp_config_tmpl = "${local.single == 1 ? local.hdp_single_config_tmpl : local.hdp_cluster_config_tmpl}"

}

###################
### SINGLE ###
###################

data "template_file" "ansible_hdp_single" {
  template = "${file("${path.module}/resources/templates/ansible_hdp_single.yml.tmpl")}"

  vars {
    ansible_hdp_master_name = "${local.public_dns[0]}"
    ansible_hdp_master_hosts = "${local.public_ips[0]}"
  }
}

# create the yaml file based on template and the input values
resource "local_file" "ansible_hdp_single_inventory" {
  count = "${local.single}"

  content  = "${data.template_file.ansible_hdp_single.rendered}"
  filename = "${local.workdir}/ansible-hosts"
}

###################
### CLUSTER ###
###################
# first the hostnames are generated - the hostnames are for the HDP cluster itself
data "template_file" "generate_datanode_hostname" {
  count = "${length(local.datanodes_dns)}"
  template = "${file("${path.module}/resources/templates/datanode_hostname.tmpl")}"

  vars {
    datanode-text = "${element(local.datanodes_ips, count.index)} ansible_host=${element(local.datanodes_dns, count.index)} ansible_user=centos ansible_ssh_private_key_file=\"~/.ssh/id_rsa\""
  }
}

# the ansible-hosts is rendered here
data "template_file" "ansible_inventory" {
  template = "${file("${path.module}/resources/templates/ansible_hdp_cluster.yml.tmpl")}"
  vars {
    ambari-ansible-text = "${local.ambari_ips} ambari_host=${local.ambari_dns} ansible_user=centos ansible_ssh_private_key_file=\"~/.ssh/id_rsa\""
    namenode1-ansible-text = "${local.namenode_1_ips} ambari_host=${local.namenode_1_dns} ansible_user=centos ansible_ssh_private_key_file=\"~/.ssh/id_rsa\""
    namenode2-ansible-text = "${local.namenode_2_ips} ambari_host=${local.namenode_2_dns} ansible_user=centos ansible_ssh_private_key_file=\"~/.ssh/id_rsa\""
    datanode-ansible-text = "${join("",data.template_file.generate_datanode_hostname.*.rendered)}"
  }
}

# create the yaml file based on template and the input values
resource "local_file" "ansible_hdp_cluster_inventory" {
  count = "${1 - local.single}"

  content  = "${data.template_file.ansible_inventory.rendered}"
  filename = "${local.workdir}/ansible-hosts"
}

###########################################


# prepare hdp config file
data "template_file" "hdp_config" {
  template = "${file("${path.module}/resources/templates/${local.hdp_config_tmpl}")}"

  vars {
    clustername = "${local.clustername}"
    ambari_version = "${local.ambari_version}"
    hdp_version = "${local.hdp_version}"
    hdp_build_number = "${local.hdp_build_number}"
    database = "${local.database}"
    ambari_services = "${local.ambari_services}"
    master_clients = "${local.master_clients}"
    master_services = "${local.master_services}"
    slave_clients = "${local.slave_clients}"
    slave_services = "${local.slave_services}"
  }
}

resource "local_file" "hdp_config_rendered" {
  depends_on = [
    "module.provision_hdp"
  ]

  content  = "${data.template_file.hdp_config.rendered}"
  filename = "${local.workdir}/hdp-config.yml"
}

resource "null_resource" "passwordless_ssh" {
  depends_on = [
    "module.provision_hdp"
  ]

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
  depends_on = [
    "null_resource.passwordless_ssh"
  ]

  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible-hosts ${path.module}/resources/install-python-packages.yml"
  }
}

resource "null_resource" "prepare_nodes" {
  depends_on = [
    "null_resource.install_python_packages",
    "local_file.ansible_hdp_cluster_inventory",
    "local_file.hdp_config_rendered",
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
  depends_on = [
    "null_resource.configure_ambari",
  ]

  # install, configure and prepare DB objects for Ranger and RangerKMS
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = "${local.public_ips[0]}"
      user     = "${local.template_user}"
      password = "${local.template_password}"
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
