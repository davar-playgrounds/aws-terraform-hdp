provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

resource "aws_instance" "test_instance" {
#resource "aws_launch_configuration" "test_instance" {
  ami = "${data.consul_keys.app.var.ami}"
  #image_id = "${data.consul_keys.app.var.ami}"
  instance_type = "${data.consul_keys.app.var.instance_type}"
  security_groups = ["aws_security_group.terraform-security-group.id"]
  #availability_zone = "${data.consul_keys.app.var.availability_zone}"
  #key_name = "${data.consul_keys.app.var.Name}"

  tags {
    Name = "${data.consul_keys.app.var.Name}"
  }
}

resource "consul_keys" "app" {
  datacenter = "${var.datacenter}"

  key {
    path = "test/master/aws/test-instance/instance_id"
    value = "${aws_instance.test_instance.id}"
  }

  key {
    path = "test/master/aws/test-instance/public_ip"
    value = "${aws_instance.test_instance.public_ip}"
  }

  key {
    path = "test/master/aws/test-instance/public_dns"
    value = "${aws_instance.test_instance.public_dns}"
  }
}
