provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = "${data.consul_keys.app.var.vpc_id}"

  tags {
    Name = "${var.name}"
  }
}

resource "consul_keys" "app" {
  datacenter = "${var.datacenter}"

  key {
    path = "test/master/aws/test-instance/igw_id"
    value = "${aws_internet_gateway.terraform_igw.id}"
  }
}
