provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

module "vpc" {
  source = "../vpc"
}

resource "aws_subnet" "terraform_subnet" {
  vpc_id     = "${module.vpc.vpc_id}"
  cidr_block = "${module.vpc.cidr_block}"

  tags {
    Name = "Terraform Subnet"
  }
}
