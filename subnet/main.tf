provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

module "vpc" {
  source = "../vpc"
}

resource "aws_subnet" "terraform_subnet" {
  vpc_id     = "${module.vpc.vpc_id}" # "${module.vpc}"  #"vpc-d5259bb0" # "${aws_vpc.main.id}"
  cidr_block = "172.31.32.0/20"

  tags {
    Name = "Terraform Subnet"
  }
}
