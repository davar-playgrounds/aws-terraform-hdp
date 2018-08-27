# comment

provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

resource "aws_instance" "app" {
  ami = "${data.consul_keys.app.var.ami}"
  instance_type = "${data.consul_keys.app.var.instance_type}"
  #availability_zone = "${data.consul_keys.app.var.availability_zone}"

  tags {
    Name = "${data.consul_keys.app.var.Name}"
  }
}
