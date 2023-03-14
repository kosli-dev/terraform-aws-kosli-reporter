locals {
  package_url = "${var.reporter_releases_host}/kosli_lambda_${var.kosli_cli_version}.zip"
  downloaded  = "downloaded_package_${md5(local.package_url)}.zip"
}

resource "null_resource" "download_package" {
  triggers = {
    downloaded = local.downloaded
  }

  provisioner "local-exec" {
    command = "curl -L -o ${local.downloaded} ${local.package_url}"
  }
}

data "null_data_source" "downloaded_package" {
  inputs = {
    id       = null_resource.download_package.id
    filename = local.downloaded
  }
}

locals {
  trigger_cron = {
    AllowExecutionFromCloudWatchCron = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.cron_every_minute.arn
    }}

  trigger_ecs_task_change = var.kosli_environment_type == "ecs" ? {AllowExecutionFromCloudWatchECS = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.ecs_task_updated[0].arn
    }} : {}

  allowed_triggers_combined = merge(local.trigger_cron, local.trigger_ecs_task_change)
}

module "reporter_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "3.3.1"

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.combined.json

  function_name          = var.name
  description            = "Send reports to the Kosli app"
  handler                = "function.handler"
  runtime                = "provided"
  local_existing_package = data.null_data_source.downloaded_package.outputs["filename"]

  role_name      = var.name
  timeout        = 30
  create_package = false
  publish        = true

  environment_variables = {
    KOSLI_COMMAND = var.kosli_command
    KOSLI_HOST      = var.kosli_host
    KOSLI_API_TOKEN = data.aws_ssm_parameter.kosli_api_token.value
  }

  allowed_triggers = local.allowed_triggers_combined

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days

  tags = var.tags
}
