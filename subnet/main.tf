provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

resource "aws_subnet" "terraform_subnet" {
  vpc_id     = "vpc-06d960ad24df293c8" # "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"

  tags {
    Name = "Terraform Subnet"
  }
}
