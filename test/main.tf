provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

#module "vpc" {
#  source = "../vpc"
#}

module "subnet" {
  source = "../subnet"
}
