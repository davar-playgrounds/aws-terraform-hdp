provider "aws" {
  region = "${data.consul_keys.app.var.region}"
}

resource "aws_instance" "test_instance" {
  count = "${data.consul_keys.app.var.no_instances}"
  ami = "${data.consul_keys.app.var.ami}"
  instance_type = "${data.consul_keys.app.var.instance_type}"
  subnet_id = "${data.consul_keys.app.var.subnet_id}"
  security_groups = ["${data.consul_keys.app.var.security_group}"]
  availability_zone = "${data.consul_keys.app.var.availability_zone}"
  key_name = "mykeypair"
  associate_public_ip_address = "true"

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = 50
  }

  tags {
    Name = "${data.consul_keys.app.var.Name}"
  }
}

/*
# write to consul
resource "consul_keys" "app" {
  datacenter = "${var.datacenter}"

  key {
     path = "test/master/aws/test-instance/instance_ids"
     value = "${join(",", aws_instance.test_instance.*.id)}"
   }
   key {
     path = "test/master/aws/test-instance/public_ips"
     value = "${join(",", aws_instance.test_instance.*.public_ip)}"
   }
   key {
     path = "test/master/aws/test-instance/public_dns"
     value = "${join(",", aws_instance.test_instance.*.public_dns)}"
  }
}
*/
