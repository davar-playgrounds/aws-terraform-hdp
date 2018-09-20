local.resource "null_resource" "clone_hdp_repo" {
  # Clone HDP repository
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook resources/clone-ansible-hortonworks.yml"
  }
}

locals {

  ambari-host = "${data.consul_keys.app.var.public_dns_ambari}"
  ambari-ip = "${data.consul_keys.app.var.public_ip_ambari}"
  master-host = "${data.consul_keys.app.var.public_dns_namenode}"
  master-ip = "${data.consul_keys.app.var.public_ip_namenode}"
  slave-host = "${data.consul_keys.app.var.public_dns_datanode}"
  slave-ip = "${data.consul_keys.app.var.public_ip_datanode}"

  clustername = "${data.consul_keys.hdp.var.hdp_cluster_name}"
  master-clients = "${data.consul_keys.hdp.var.master-clients}"
  master-services = "${data.consul_keys.hdp.var.master-services}"

  workdir="${path.cwd}/output/hdp-server/${data.consul_keys.mine.var.hdp_cluster_name}"
}

# prepare hosts file
data "template_file" "ansible_hosts" {
  template = "${file("${path.module}/resources/templates/ansible-hosts.tmpl")}"

  vars {
    ambari-host = "${local.public_dns_ambari}"
    ambari-ip = "${local.var.public_ip_ambari}"
    master-host = "${local.public_dns_namenode}"
    master-ip = "${local.public_ip_namenode}"
    slave-host = "${local.public_dns_datanode}"
    slave-ip = "${local.public_ip_datanode}"
  }
}

resource "local_file" "ansible_hosts_rendered" {
  content  = "${data.template_file.ansible_hosts.rendered}"
  filename = "${local.workdir}/output/ansible-hosts"
}

# prepare hdp config file
data "template_file" "hdp_config" {
  template = "${file("${path.module}/resources/templates/hdp-cluster-config.tmpl")}"

  vars {
    clustername = "${local.var.hdp_cluster_name}"
    master-clients = "${local.var.master-clients}"
    master-services = "${local.var.master-services}"
  }
}

resource "local_file" "hdp_config_rendered" {
  content  = "${data.template_file.hdp_config.rendered}"
  filename = "${local.workdir}/output/hdp-cluster-config.yml"
}

resource "null_resource" "passwordless_ssh" {
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts ${local.workdir}/resources/passwordless-ssh.yml"
  }
}

resource "null_resource" "install_python_packages" {
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts ${local.workdir}/resources/install-python-packages.yml"
  }
}

resource "null_resource" "prepare_nodes" {
  depends_on = [
    "null_resource.install_python_packages",
    "local_file.ansible_hosts_rendered",
    "local_file.hdp_config_rendered",
  ]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static --extra-vars=${var.hdp_spec} ${local.workdir}/resources/ansible-hortonworks/playbooks/prepare_nodes.yml"
  }
}

resource "null_resource" "install_ambari" {
  depends_on = ["null_resource.prepare_nodes"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static --extra-vars=${var.hdp_spec} ${local.workdir}/resources/ansible-hortonworks/playbooks/install_ambari.yml"
  }
}

resource "null_resource" "configure_ambari" {
  depends_on = ["null_resource.install_ambari"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static --extra-vars=${var.hdp_spec} ${local.workdir}/resources/ansible-hortonworks/playbooks/configure_ambari.yml"
  }
}

resource "null_resource" "apply_blueprint" {
  depends_on = ["null_resource.configure_ambari"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}${var.hdp_spec} ${local.workdir}/resources/ansible-hortonworks/playbooks/apply_blueprint.yml"
  }
}

resource "null_resource" "post_install" {
  depends_on = ["null_resource.apply_blueprint"]
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/output/ansible-hosts --extra-vars=cloud_name=static --extra-vars=@${local.workdir}${var.hdp_spec} ${local.workdir}/resources/ansible-hortonworks/playbooks/post_install.yml"
  }
}
