provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}
/*
resource "aws_security_group" "terraform-security-group" {
  #name = "${var.security_group_name}"
  vpc_id = "${data.consul_keys.app.var.vpc_id}"
  id = "${data.consul_keys.app.var.default_security_group_id}"
  ingress {
    cidr_blocks = ["${data.consul_keys.app.var.cidr_block}"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
}
*/

resource "aws_security_group_rule" "test_rule" {
  type        = "ingress"
  description = "Test rule"
  from_port   = "22"
  to_port     = "22"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${data.consult_keys.app.var.default_security_group_id}"
}

resource "consul_keys" "app" {
  datacenter = "${var.datacenter}"

  key {
    path = "test/master/aws/test-instance/security_group"
    value = "${aws_security_group.terraform-security-group.id}"
  }

  key {
    path = "test/master/aws/test-instance/security_group_name"
    value = "${aws_security_group.terraform-security-group.name}"
  }
}
