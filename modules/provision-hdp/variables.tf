variable "path_in_consul" {
  default   = "test/master/aws/test-instance"
}

data "consul_keys" "app" {
  key {
    name    = "public_ip"
    path    = "${var.path_in_consul}/public_ip"
  }
}
