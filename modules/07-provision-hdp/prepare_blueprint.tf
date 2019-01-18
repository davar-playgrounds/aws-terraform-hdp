# populate the template file with variables
data "template_file" "dynamic_blueprint" {
  template = "${file("${path.module}/resources/templates/blueprints/blueprint_hdfs_only.json.tmpl")}"
  vars {
    s3a_access_key = "${local.s3a_access_key}"
    s3a_secret_key = "${local.s3a_secret_key}"
  }
}

# create the yaml file based on template and the input values
resource "local_file" "dynamic_blueprint_render" {
  content  = "${data.template_file.dynamic_blueprint.rendered}"
  filename = "${local.workdir}/blueprint_hdfs_only.json"
}
