module "provision_hdp" {
  source             = "../06-instance"
  cluster_type       = "${var.cluster_type}"
}

locals {

  public_dns = "${module.provision_hdp.public_dns}"
  public_ips = "${module.provision_hdp.public_ip}"

  ambari_host = "${local.public_dns[0]}"
  ambari_ip = "${local.public_ips[0]}"

  master_host = "${local.public_dns[1]}"
  master_ip = "${local.public_ips[1]}"

  slave_host = "${local.public_dns[1]}"
  slave_ip = "${local.public_ips[1]}"

  clustername = "${data.consul_keys.hdp.var.hdp_cluster_name}"
  ambari_version = "${data.consul_keys.hdp.var.ambari_version}"
  hdp_version = "${data.consul_keys.hdp.var.hdp_version}"
  hdp_build_number = "${data.consul_keys.hdp.var.hdp_build_number}"

  ambari_services = "${data.consul_keys.hdp.var.ambari_services}"
  master_clients = "${data.consul_keys.hdp.var.master_clients}"
  master_services = "${data.consul_keys.hdp.var.master_services}"
  #slave_clients = "${data.consul_keys.hdp.var.master_clients}"
  #slave_services = "${data.consul_keys.hdp.var.slave_services}"

  workdir="${path.cwd}/output/hdp-server/${local.clustername}"
}

# prepare hosts file
data "template_file" "ansible_hosts" {
  template = "${file("${path.module}/resources/templates/ansible-hosts.tmpl")}"

  vars {
    ambari_host = "${local.ambari_host}"
    ambari_ip = "${local.ambari_ip}"
    master_host = "${local.master_host}"
    master_ip = "${local.master_ip}"
    slave_host = "${local.slave_host}"
    slave_ip = "${local.slave_ip}"
  }
}

resource "local_file" "ansible_hosts_rendered" {
  depends_on = [
    "module.provision_hdp"
  ]
  content  = "${data.template_file.ansible_hosts.rendered}"
  filename = "${local.workdir}/output/ansible-hosts"
}

# prepare hdp config file
data "template_file" "hdp_config" {
  template = "${file("${path.module}/resources/templates/hdp-cluster-config.tmpl")}"

  vars {
    clustername = "${local.clustername}"
    ambari_version = "${local.ambari_version}"
    hdp_version = "${local.hdp_version}"
    hdp_build_number = "${local.hdp_build_number}"
    ambari_services = "${local.ambari_services}"
    master_clients = "${local.master_clients}"
    master_services = "${local.master_services}"
    #slave_clients = "${local.slave_clients}"
    #slave_services = "${local.slave_services}"
  }
}

resource "local_file" "hdp_config_rendered" {
  depends_on = [
    "module.provision_hdp"
  ]

  content  = "${data.template_file.hdp_config.rendered}"
  filename = "${local.workdir}/output/hdp-cluster-config.yml"
}

resource "null_resource" "passwordless_ssh" {
  depends_on = [
    "module.provision_hdp"
  ]

  provisioner "local-exec" {
    command = <<-EOF
      echo "Sleeping for 10 seconds..."; sleep 10
    EOF
  }

  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts ${path.module}/resources/passwordless-ssh.yml"
  }
}

resource "null_resource" "install_python_packages" {
  depends_on = [
    "null_resource.passwordless_ssh"
  ]

  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts ${path.module}/resources/install-python-packages.yml"
  }
}

resource "null_resource" "prepare_nodes" {
  depends_on = [
    "null_resource.install_python_packages",
    "local_file.ansible_hosts_rendered",
    "local_file.hdp_config_rendered",
  ]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static ${path.module}/resources/ansible-hortonworks/playbooks/prepare_nodes.yml"
  }
}

resource "null_resource" "install_ambari" {
  depends_on = ["null_resource.prepare_nodes"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}${var.hdp_spec} ${path.module}/resources/ansible-hortonworks/playbooks/install_ambari.yml"
  }
}

resource "null_resource" "configure_ambari" {
  depends_on = ["null_resource.install_ambari"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}${var.hdp_spec} ${path.module}/resources/ansible-hortonworks/playbooks/configure_ambari.yml"
  }
}

resource "null_resource" "apply_blueprint" {
  depends_on = ["null_resource.configure_ambari"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}${var.hdp_spec} ${path.module}/resources/ansible-hortonworks/playbooks/apply_blueprint.yml"
  }
}

resource "null_resource" "post_install" {
  depends_on = ["null_resource.apply_blueprint"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}${var.hdp_spec} ${path.module}/resources/ansible-hortonworks/playbooks/post_install.yml"
  }
}
