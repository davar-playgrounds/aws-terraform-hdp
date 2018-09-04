output "vpc_id" {
  value = "${aws_vpc.test_vpc.id}"
}

output "cidr_block" {
  value = "${aws_vpc.test_vpc.cidr_block}"
}
