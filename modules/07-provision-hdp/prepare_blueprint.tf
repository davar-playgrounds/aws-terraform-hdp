/*data "template_file" "dynamic_blueprint_components" {
  count = "${length(local.components)}"
  template = "${file("${path.module}/resources/templates/blueprints/components.tmpl")}"
  vars {
    #component_text = "${join(",", local.components)},"
    component_text = " { \"name\" : \"${element(local.components, count.index)}\"},"
  }
}*/

# populate the template file with variables
data "template_file" "dynamic_blueprint" {
  template = "${file("${path.module}/resources/templates/blueprints/blueprint_hdfs_only.json.tmpl")}"
  vars {
    s3a_access_key = "${local.s3a_access_key}"
    s3a_secret_key = "${local.s3a_secret_key}"
    postgres_server = "localhost"
    components_1 = "${local.components}"
    # -2 is to cut the LF and last comma
    #components_1 = "${substr(join("",data.template_file.dynamic_blueprint_components.*.rendered), 0, length(join("",data.template_file.dynamic_blueprint_components.*.rendered))-2)}"
  }
}

# create the yaml file based on template and the input values
resource "local_file" "dynamic_blueprint_render" {
  content  = "${data.template_file.dynamic_blueprint.rendered}"
  filename = "${local.workdir}/blueprint_hdfs_only.json"
}
