# Download Kosli binary
locals {
  kosli_src_path = "${path.module}/builds/kosli_${var.kosli_cli_version}"
}

resource "null_resource" "download_and_unzip" {
  triggers = {
    downloaded = "${local.kosli_src_path}/kosli.tar.gz"
  }

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${local.kosli_src_path}/
      curl -Lo ${local.kosli_src_path}/kosli.tar.gz https://github.com/kosli-dev/cli/releases/download/v${var.kosli_cli_version}/kosli_${var.kosli_cli_version}_linux_amd64.tar.gz
      tar -xf ${local.kosli_src_path}/kosli.tar.gz -C ${local.kosli_src_path}/
    EOT
  }
}

# Prepare reporter execution script
locals {
  kosli_command_mandatory_parameter = {
    s3     = "bucket"
    ecs    = "cluster"
    lambda = "function-names"
  }
  kosli_command_mandatory = "kosli snapshot ${var.kosli_environment_type} ${var.kosli_environment_name} --${local.kosli_command_mandatory_parameter[var.kosli_environment_type]} ${var.reported_aws_resource_name}"
  kosli_command           = var.kosli_command_optional_parameters == "" ? local.kosli_command_mandatory : "${local.kosli_command_mandatory} ${var.kosli_command_optional_parameters}"
}

data "template_file" "function" {
  template = file("${path.module}/src/function_template.sh")

  vars = {
    KOSLI_COMMAND = local.kosli_command
  }
}

resource "local_file" "function" {
  content  = data.template_file.function.rendered
  filename = "${path.module}/src/function.sh"
}
