provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

resource "aws_vpc" "test_vpc" {
  cidr_block = "${var.cidr_block}"
  enable_dns_hostnames = true

  tags {
    Name = "Terraform VPC"
  }
}

resource "consul_keys" "app" {
  datacenter = "${var.datacenter}"

  key {
    path = "test/master/aws/test-instance/vpc_id"
    value = "${aws_vpc.test_vpc.id}"
  }
  key {
    path = "test/master/aws/test-instance/cidr_block"
    value = "${aws_vpc.test_vpc.cidr_block}"
  }
  key {
    path = "test/master/aws/test-instance/main_route_table_id"
    value = "${aws_vpc.test_vpc.main_route_table_id}"
  }
  key {
    path = "test/master/aws/test-instance/default_security_group_id"
    value = "${aws_vpc.test_vpc.default_security_group_id}"
  }
}
