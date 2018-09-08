provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

resource "aws_security_group_rule" "port_22_to_world" {
  type        = "ingress"
  description = "SSH to world"
  from_port   = "22"
  to_port     = "22"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${data.consul_keys.app.var.default_security_group_id}"
}

resource "aws_security_group_rule" "port_8080_to_world" {
  type        = "ingress"
  description = "Ambari to world"
  from_port   = "8080"
  to_port     = "8080"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${data.consul_keys.app.var.default_security_group_id}"
}

resource "consul_keys" "app" {
  datacenter = "${var.datacenter}"

  key {
    path = "test/master/aws/test-instance/port_22_to_world"
    value = "${aws_security_group_rule.port_22_to_world.id}"
  }
  key {
    path = "test/master/aws/test-instance/port_8080_to_world"
    value = "${aws_security_group_rule.port_8080_to_world.id}"
  }
}
