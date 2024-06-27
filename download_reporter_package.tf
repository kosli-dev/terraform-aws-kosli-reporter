locals {
  package_url = "${var.reporter_releases_host}/kosli_lambda_${var.kosli_cli_version}.zip"
  downloaded  = "downloaded_package_${md5(local.package_url)}.zip"
}

resource "terraform_data" "download_package" {
  input = local.downloaded

  triggers_replace = [
    local.downloaded
  ]

  provisioner "local-exec" {
    command = "curl -L -o ${local.downloaded} ${local.package_url}"
  }
}