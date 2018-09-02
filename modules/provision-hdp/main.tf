resource "null_resource" "clone_hdp_repo" {
  # Clone HDP repository
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook resources/clone-ansible-hortonworks.yml"
  }
}

# add install hdp depends_on
data "template_file" "ansible_hosts" {
  template = "${file("${path.module}/resources/templates/ansible-hosts")}"
  count    = "${data.consul_keys.mine.var.count}"

  vars {
    hostname     = "${local.hostnames[count.index]}"
    username     = "${data.consul_keys.mine.var.template_user}"
    password     = "${data.consul_keys.mine.var.template_password}"
    ipv4_address = "${local.public_ips[count.index]}"
  }
}
