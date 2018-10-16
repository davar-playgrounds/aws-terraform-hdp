module r_server {
  source             = "../06-instance"
  cluster_type       = "r-server"
}

locals {
  public_ip = "${data.consul_keys.app.var.public_ip}"
  public_dns = "${data.consul_keys.app.var.public_dns}"
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
