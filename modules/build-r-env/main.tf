locals {
  public_ip = "${data.consul_keys.app.var.public_ip}"
  public_dns = "${data.consul_keys.app.var.public_dns}"
  singledir = "${path.cwd}/../single"
  workdir="${path.cwd}/output"
}

data "template_file" "ansible_hosts_tmpl" {
  template = "${file("${path.module}/resources/templates/ansible-hosts.tmpl")}"

  vars {
    public_ip = "${local.public_ip}"
    public_dns = "${local.public_dns}"
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

resource "null_resource" "run_test" {
  depends_on = [
    "null_resource.install_r"
  ]

  provisioner "local-exec" {
    command = "export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook --inventory=${local.workdir}/ansible_hosts ${path.module}/resources/ansible/run_test.yml"
  }
}
