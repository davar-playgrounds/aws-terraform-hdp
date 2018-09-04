resource "null_resource" "clone_hdp_repo" {
  # Clone HDP repository
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook resources/clone-ansible-hortonworks.yml"
  }
}

data "template_file" "ansible_hosts" {
  template = "${file("${path.module}/resources/templates/ansible-hosts.tmpl")}"
  #count    = "${data.consul_keys.mine.var.count}"

  vars {
    master-host = "${data.consul_keys.app.var.public_dns_namenode}"
    slave-host = "${data.consul_keys.app.var.public_dns_datanode}"
  }
}

resource "local_file" "ansible_hosts_inventory" {
  content  = "${data.template_file.ansible_hosts.rendered}"
  filename = "${local.workdir}/ansible-hosts"
}

#TO-DO
# run ansible-hortonworks - depends on both above
resource "null_resource" "prepare_nodes" {
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook -v -e cloud_name=static playbooks/prepare_nodes.yml --inventory=${local.workdir}/ansible-hosts --extra-vars=${local.workdir}/resources/hdp-cluster-minimal.yml"
  }
}
