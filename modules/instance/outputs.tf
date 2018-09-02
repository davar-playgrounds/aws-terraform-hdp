output "instance id" {
  value = "${aws_launch_configuration.test_instance.id}"
}

output "public_ip" {
  value = "${aws_launch_configuration.test_instance.public_ip}"
}
