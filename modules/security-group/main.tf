provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

module "vpc" {
  source = "../vpc"
}

module "subnet" {
  source = "../subnet"
}

resource "aws_security_group" "security-group" {
  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    cidr_blocks = ["${module.vpc.cidr_block}"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
}
