resource "null_resource" "clone_hdp_repo" {
  # Clone HDP repository
  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook resources/clone-ansible-hortonworks.yml"
  }
}

# add install hdp depends_on
data "template_file" "ansible_hosts" {
  template = "${file("${path.module}/resources/templates/ansible-hosts.tmpl")}"
  #count    = "${data.consul_keys.mine.var.count}"

  vars {
    hostname     = "${data.consul_keys.app.var.public_ip}"
  }
}

resource "local_file" "ansible_hosts_inventory" {
  content  = "${data.template_file.ansible_hosts.rendered}"
  filename = "${local.workdir}/ansible-hosts"
}
