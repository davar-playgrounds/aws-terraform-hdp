provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

module "subnet" {
  source = "../subnet"
}

resource "aws_security_group" "security_group" {

  name = "${var.security_group_name}"

  vpc_id = "${var.vpc_id}"

  ingress {
    cidr_blocks = ["${var.cidr_block}"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
}
