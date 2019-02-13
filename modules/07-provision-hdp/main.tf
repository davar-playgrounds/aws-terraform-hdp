module "provision_hdp" {
  source             = "../06-instance"
  cluster_type       = "${var.cluster_type}"
}

# all variables used in the script are in locals block
locals {

  type = "${data.consul_keys.hdp.var.type}" # single or cluster
  no_datanodes = "${data.consul_keys.hdp.var.no_datanodes}" # number of datanodes in cluster
  no_namenodes = "${local.type == "cluster" ? data.consul_keys.hdp.var.no_namenodes : 0}" # number of namenodes in cluster

  workdir="${path.cwd}/output/hdp-server/${local.clustername}"

  ## all DNS and IP needed for the Hadoop cluster
  public_ips = "${module.provision_hdp.public_ip}"
  public_dns = "${module.provision_hdp.public_dns}"
  private_dns = "${module.provision_hdp.private_dns}"

  #single = "${local.no_instances == 1 ? 1 : 0}" # is it a single node or multi?

  #############################
  ### variables for cluster ###
  #############################

  ## first server is ambari - no matter if single or cluster
  ambari_ips = "${local.public_ips[0]}"
  ambari_dns = "${local.public_dns[0]}"
  ambari_dns_private = "${local.private_dns[0]}"


  # indices to create the dynamic code in case single node cluster is also used
  # if a single node cluster -> indices are 0, else second server is namenode 1,
  # third server is namenode 2 and all the others are datanodes
  namenode_idx = "${local.no_datanodes == 0 ? 0 : 1}"
  datanode_idx = "${local.no_datanodes == 0 ? 0 : 1 + local.no_namenodes}"


  # next 2 servers are dedicated namenodes
  # namenode_dns holds value of dns for the HDP cluster (Ambari server excluded)
  # these are only used when multinode cluster, otherwise they point to first server
  namenodes_ips = "${slice(local.public_ips, local.namenode_idx, local.namenode_idx + local.no_namenodes)}"
  namenodes_dns = "${slice(local.public_dns, local.namenode_idx, local.namenode_idx + local.no_namenodes)}"
  namenodes_dns_private = "${slice(local.private_dns, local.namenode_idx, local.namenode_idx + local.no_namenodes)}"
  # workaround in case it is a single node cluster
  # in if statement - both get evaluated
  dummy_list = ["foo1", "foo2"]
  namenodes_dns_private_temp = "${concat(local.namenodes_dns_private, local.dummy_list)}"

  nn1_dns = "${local.type == "cluster" ? local.namenodes_dns_private_temp[0] : local.ambari_dns_private}"
  nn2_dns = "${local.type == "cluster" ? local.namenodes_dns_private_temp[1] : local.ambari_dns_private}"

  ## if multinode cluster: rest of the servers are datanodes (from and including server 4)
  datanodes_ips = "${slice(local.public_ips, local.datanode_idx, length(local.public_ips))}"
  datanodes_dns = "${slice(local.public_dns, local.datanode_idx, length(local.public_dns))}"
  datanodes_dns_private = "${slice(local.private_dns, local.datanode_idx, length(local.public_dns))}"

  #########################
  ### variables for HDP ###
  #########################

  clustername = "${data.consul_keys.hdp.var.hdp_cluster_name}" # name of HDP cluster
  ambari_version = "${data.consul_keys.hdp.var.ambari_version}"
  hdp_version = "${data.consul_keys.hdp.var.hdp_version}"
  hdp_build_number = "${data.consul_keys.hdp.var.hdp_build_number}"
  database = "${data.consul_keys.hdp.var.database}" # database for metastore - postgres

  ambari_services = "${data.consul_keys.hdp.var.ambari_services}" # services on management server
  master_services = "${data.consul_keys.hdp.var.master_services}" # services on namenodes
  slave_services = "${data.consul_keys.hdp.var.slave_services}" # services on slaves (workers)

  hdp_config_tmpl = "hdp-config.yml.tmpl" # cluster configuration template - one for all

  gpfs_quorum = "${distinct(concat(local.namenodes_dns_private, local.datanodes_dns_private))}" # for config hdfs-site

  #########################
  ### variables for s3a ###
  #########################

  s3a = "${data.consul_keys.hdp.var.s3a}"
  s3a_access_key = "${data.consul_keys.s3a.var.s3a_access_key}"
  s3a_secret_key = "${data.consul_keys.s3a.var.s3a_secret_key}"
}
##########################
/*
resource "null_resource" "write_out" {
  depends_on = ["module.provision_hdp"]

  provisioner "local-exec" {
    command = <<EOF
      echo "*********************************************************"
      echo "namenodes_dns_private: ${join(", ", local.namenodes_dns_private)}"
EOF
  }
}
*/
resource "null_resource" "passwordless_ssh" {
  depends_on = ["module.provision_hdp"]

  provisioner "local-exec" {
    command = <<EOF
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
    "local_file.ansible_inventory_single_render",
    "local_file.ansible_inventory_cluster_render",
    "local_file.hdp_config_rendered"
  ]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}/hdp-config.yml --extra-vars=blueprint_file=${local.workdir}/${var.cluster_type}.json ${path.module}/resources/ansible-hortonworks/playbooks/prepare_nodes.yml"
  }
}

resource "null_resource" "install_ambari" {
  depends_on = ["null_resource.prepare_nodes"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}/hdp-config.yml --extra-vars=blueprint_file=${local.workdir}/${var.cluster_type}.json ${path.module}/resources/ansible-hortonworks/playbooks/install_ambari.yml"
  }
}

resource "null_resource" "configure_ambari" {
  depends_on = ["null_resource.install_ambari"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}/hdp-config.yml --extra-vars=blueprint_file=${local.workdir}/${var.cluster_type}.json ${path.module}/resources/ansible-hortonworks/playbooks/configure_ambari.yml"
  }
}

## configure postgres for Ranger and Ranger KMS
resource "null_resource" "configure_postgres" {
  count = "${local.database == "postgres" ? "1" : "0"}"
  depends_on = ["null_resource.configure_ambari"]

  # install, configure and prepare DB objects for Ranger and RangerKMS
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = "${local.ambari_ips}"
      user     = "centos" #"${local.template_user}"
      private_key = "${file("/home/centos/.ssh/id_rsa")}"
      #password = "${local.template_password}"
    }
    script = "${path.module}/resources/scripts/config_postgres.sh"
  }
}

resource "null_resource" "apply_blueprint" {
  depends_on = ["null_resource.configure_postgres",
                "null_resource.configure_ambari"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}/hdp-config.yml --extra-vars=blueprint_file=${local.workdir}/${var.cluster_type}.json ${path.module}/resources/ansible-hortonworks/playbooks/apply_blueprint.yml"
  }
}

resource "null_resource" "post_install" {
  depends_on = ["null_resource.apply_blueprint"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}/hdp-config.yml --extra-vars=blueprint_file=${local.workdir}/${var.cluster_type}.json ${path.module}/resources/ansible-hortonworks/playbooks/post_install.yml"
  }
}
