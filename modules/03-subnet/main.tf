provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}
/*
resource "aws_subnet" "test_subnet" {
  vpc_id     = "${data.consul_keys.app.var.vpc_id}"
  cidr_block = "${data.consul_keys.app.var.cidr_block}"
  availability_zone = "${data.consul_keys.app.var.availability_zone}"
  map_public_ip_on_launch = true

  tags {
    Name = "Terraform Subnet"
  }
}
*/
resource "aws_route" "route" {
  route_table_id            = "${data.consul_keys.app.var.main_route_table_id}"
  destination_cidr_block    = "0.0.0.0/0"
  #depends_on                = ["aws_route_table.testing"]
}

resource "consul_keys" "app" {
  datacenter = "${var.datacenter}"

  key {
    path = "test/master/aws/test-instance/route_id"
    value = "${aws_route.route.id}"
  }
}
