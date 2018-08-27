provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

module "subnet" {
  source = "../subnet"
}

resource "aws_security_group" "security_group" {
  
  name = "Terraform Security Group"

  vpc_id = "${module.subnet.vpc_id}"

  ingress {
    cidr_blocks = ["${module.subnet.cidr_block}"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
}
