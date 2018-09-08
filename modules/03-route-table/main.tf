provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

resource "aws_route" "terraform_route_table" {
  route_table_id            = "${data.consul_keys.app.var.main_route_table_id}"
  gateway_id                = "${data.consul_keys.app.var.igw_id}"
  destination_cidr_block    = "0.0.0.0/0"
}

resource "consul_keys" "app" {
  datacenter = "${var.datacenter}"

  key {
    path = "test/master/aws/test-instance/route_id"
    value = "${aws_route.route.id}"
  }
}


resource "consul_keys" "app" {
  datacenter = "${var.datacenter}"

  key {
    path = "test/master/aws/test-instance/terraform_route_table"
    value = "${aws_route_table.terraform_route_table.id}"
  }
}
