provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

module "vpc" {
  source = "../modules/01-vpc"
}

module "gateway" {
  source = "../modules/02-gateway"
}
