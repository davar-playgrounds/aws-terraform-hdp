provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "Terraform VPC"
  }
}
