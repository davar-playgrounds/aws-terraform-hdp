output "vpc_id" {
  value = "${aws_subnet.terraform_subnet.vpc_id}"
}

output "subnet_id" {
  value = "${aws_subnet.terraform_subnet.id}"
}
