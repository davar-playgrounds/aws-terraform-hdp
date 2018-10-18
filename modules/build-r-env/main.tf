module "r_server" {
  source             = "../single"
  cluster_type       = "r-server"
}

resource "null_resource" "delay" {
  depends_on = [
    "module.r_server"
  ]
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

locals {
  #public_ip = "${data.consul_keys.app.var.public_ip}"
  #public_dns = "${data.consul_keys.app.var.public_dns}"
  workdir="${path.cwd}/output"
}

data "template_file" "ansible_hosts_tmpl" {
  depends_on = [
    "null_resource.delay"
  ]
  template = "${file("${path.module}/resources/templates/ansible-hosts.tmpl")}"

  vars {
    public_ip = "${data.consul_keys.app.var.public_ip}" #"${local.public_ip}"
    public_dns = "${data.consul_keys.app.var.public_dns}" #"${local.public_dns}"
  }
}

resource "local_file" "ansible_hosts_render" {
  content  = "${data.template_file.ansible_hosts_tmpl.rendered}"
  filename = "${local.workdir}/ansible_hosts"
}

resource "null_resource" "install_r" {
  depends_on = [
    "local_file.ansible_hosts_render"
  ]

  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible_hosts ${path.module}/resources/ansible/install_r.yml"
  }
}
