provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

#module "subnet" {
#  source = "../subnet"
#}

resource "aws_security_group" "${var.security_group_name}" {

  name = "${var.security_group_name}"

  vpc_id = "${data.consul_keys.app.var.vpc_id}"

  ingress {
    cidr_blocks = ["${data.consul_keys.app.var.cidr_block}"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
}

resource "consul_keys" "app" {
  datacenter = "${var.datacenter}"

  key {
    path = "test/master/aws/test-instance/security_group"
    value = "${aws_security_group.security_group.id}"
  }

  key {
    path = "test/master/aws/test-instance/security_group_name"
    value = "${aws_security_group.security_group.name}"
  }
}
