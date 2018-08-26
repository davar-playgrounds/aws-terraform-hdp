output "vpc_id" {
  value = "${aws_subnet.terraform_subnet.vpc_id}"
}

output "subnet id" {
  value = "${aws_subnet.terraform_subnet.id}"
}
