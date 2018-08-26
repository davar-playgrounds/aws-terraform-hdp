output "ip" {
  value = "${app.ip.public_ip}"
}

output "public_ip" {
  value = "${aws_instance.app.public_ip}"
}
