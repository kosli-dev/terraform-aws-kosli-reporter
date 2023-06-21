module "reporter_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.18.0"

  attach_policy_json = true
  policy_json        = var.create_role ? data.aws_iam_policy_document.combined[0].json : null

  function_name = var.name
  description   = "Send reports to the Kosli app"
  handler       = "function.handler"
  runtime       = "provided"

  source_path = [
    "${path.module}/src/bootstrap",
    "${path.module}/src/function.sh",
    "${local.kosli_src_path}/kosli"
  ]

  role_name      = var.create_role ? var.name : null
  timeout        = 30
  create_package = true
  publish        = true
  create_role    = var.create_role
  lambda_role    = var.create_role ? "" : var.role_arn

  environment_variables = {
    KOSLI_HOST      = var.kosli_host
    KOSLI_API_TOKEN = data.aws_ssm_parameter.kosli_api_token.value
    KOSLI_ORG       = var.kosli_org
  }

  allowed_triggers = local.allowed_triggers_combined

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days

  tags = var.tags

  depends_on = [
    null_resource.download_and_unzip,
    local_file.function
  ]
}
