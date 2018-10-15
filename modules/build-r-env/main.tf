module r_server {
  source             = "../spectrum-scale"
}

provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

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
  datacenter = "${var.datacenter}"

  key {
    path = "test/master/aws/test-instance/single/instance_id"
    value = "${aws_instance.test_instance.*.id[0]}"
  }
  key {
    path = "test/master/aws/test-instance/single/public_ip"
    value = "${aws_instance.test_instance.*.public_ip[0]}"
  }
  key {
    path = "test/master/aws/test-instance/single/public_dns"
    value = "${aws_instance.test_instance.*.public_dns[0]}"
  }

}
