output "vpc_id" {
  value = "${aws_vpc.test_vpc.id}"
}

output "cidr_block" {
  value = "${aws_vpc.test_vpc.cidr_block}"
}

output "main_route_table_id" {
  value = "${aws_vpc.test_vpc.main_route_table_id}"
}
