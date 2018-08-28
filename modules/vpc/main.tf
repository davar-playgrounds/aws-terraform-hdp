provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name = "Terraform VPC"
  }
}

resource "consul_keys" "app" {
  datacenter = "dc1"

  key {
    path = "test/master/aws/test-instance/aws_vpc"
    value = "${aws_vpc.test_vpc.id}"
  }

  key {
    path = "test/master/aws/test-instance/bla"
    value = "BLAAA"
  }
}
