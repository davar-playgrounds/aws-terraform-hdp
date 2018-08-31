provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

resource "aws_instance" "test_instance" {
  ami = "${data.consul_keys.app.var.ami}"
  instance_type = "${data.consul_keys.app.var.instance_type}"
  #availability_zone = "${data.consul_keys.app.var.availability_zone}"

  tags {
    Name = "${data.consul_keys.app.var.Name}"
  }
}

resource "consul_keys" "app" {
  datacenter = "${datacenter}"

  key {
    path = "test/master/aws/test-instance/instance_id"
    value = "${aws_instance.test_instance.id}"
  }
}
