provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

resource "aws_route_table" "terraform_route_table" {
  vpc_id = "${data.consul_keys.app.var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"# "${data.consul_keys.app.var.cidr_block}"
    gateway_id = "${data.consul_keys.app.var.igw_id}"
  }

  tags {
    Name = "${var.name}"
  }
}

resource "consul_keys" "app" {
  datacenter = "${var.datacenter}"

  key {
    path = "test/master/aws/test-instance/terraform_route_table"
    value = "${aws_route_table.terraform_route_table.id}"
  }
}
