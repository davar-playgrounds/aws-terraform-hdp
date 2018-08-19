provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

# Configure the Consul provider
provider "consul" {
  address    = "${var.consul_server}:${var.consul_port}"
  datacenter = "${var.datacenter}"
}

resource "aws_instance" "app" {
  ami = "${data.consul_keys.app.var.ami}"
  instance_type = "${data.consul_keys.app.var.instance_type}"

  tags {
    Name = "${data.consul_keys.app.var.Name}"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "mykey"
  public_key = "${data.consul_keys.app.var.key_pair}"

}
