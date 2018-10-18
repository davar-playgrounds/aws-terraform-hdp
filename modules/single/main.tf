provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

/*
provider "consul" {
  address    = "${var.consul_server}:${var.consul_port}"
  datacenter = "${var.datacenter}"
}*/

resource "aws_instance" "test_instance" {
  count = "${data.consul_keys.app.var.no_instances}"
  ami = "${data.consul_keys.app.var.ami}"
  instance_type = "${data.consul_keys.app.var.instance_type}"
  subnet_id = "${data.consul_keys.app.var.subnet_id}"
  security_groups = ["${data.consul_keys.app.var.security_group}"]
  availability_zone = "${data.consul_keys.app.var.availability_zone}"
  key_name = "mykeypair"
  associate_public_ip_address = "true"

  tags {
    Name = "${data.consul_keys.app.var.Name}"
  }

}

resource "consul_keys" "app" {
  depends_on = [
    "aws_instance.test_instance"
  ]

  datacenter = "${var.datacenter}"
  key {
    path = "test/master/aws/test-instance/single/${var.cluster_type}/instance_id"
    value = "${aws_instance.test_instance.id}"
  }
  key {
    path = "test/master/aws/test-instance/single/${var.cluster_type}/public_ip"
    value = "${aws_instance.test_instance.public_ip}"
  }
  key {
    path = "test/master/aws/test-instance/single/${var.cluster_type}/public_dns"
    value = "${aws_instance.test_instance.public_dns}"
  }

}
