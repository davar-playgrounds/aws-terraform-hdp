# populate the template file with variables
data "template_file" "dynamic_blueprint" {
  template = "${file("${path.module}/resources/templates/blueprints/${var.cluster_type}.json.tmpl")}"
  vars {
    s3a_access_key = "${local.s3a_access_key}"
    s3a_secret_key = "${local.s3a_secret_key}"
    postgres_server = "localhost"
    master_services = "${local.master_services}"
    clustername = "${local.clustername}"

    # only for cluster
    ambari_services = "${local.ambari_services}"
    slave_services = "${local.slave_services}"
    nn1_dns =  "${local.nn1_dns}"
    nn2_dns =  "${local.nn2_dns}"
    qjournal = "qjournal://${join(";", formatlist("%s:8485", local.namenodes_dns_private))}/${local.clustername}"
    gpfs_quorum = "${join(",", local.gpfs_quorum)}"
    zookeeper_quorum = "${join(",", formatlist("%s:2181", local.gpfs_quorum))}"
  }
}

# create the yaml file based on template and the input values
resource "local_file" "dynamic_blueprint_render" {
  content  = "${data.template_file.dynamic_blueprint.rendered}"
  filename = "${local.workdir}/${var.cluster_type}.json"
}
