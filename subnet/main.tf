provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

resource "aws_subnet" "terraform_subnet" {
  vpc_id     = "vpc-d5259bb0" # "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/16"

  tags {
    Name = "Terraform Subnet"
  }
}
