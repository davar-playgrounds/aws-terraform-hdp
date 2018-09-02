provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

#module "vpc" {
#  source = "../vpc"
#}

resource "aws_subnet" "test_subnet" {
  vpc_id     = "${data.consul_keys.app.var.vpc_id}"
  cidr_block = "${data.consul_keys.app.var.cidr_block}"
  availability_zone = "${data.consul_keys.app.var.availability_zone}"

  tags {
    Name = "Terraform Subnet"
  }
}

resource "consul_keys" "app" {
  datacenter = "${var.datacenter}"

  key {
    path = "test/master/aws/test-instance/subnet_id"
    value = "${aws_subnet.test_subnet.id}"
  }
}
