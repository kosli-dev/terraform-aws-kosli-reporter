module "reporter_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.7.0"

  attach_policy_json = true
  policy_json        = var.create_role ? data.aws_iam_policy_document.combined[0].json : null

  function_name          = var.name
  description            = var.lambda_description
  handler                = "main.lambda_handler"
  runtime                = "python3.11"
  local_existing_package = terraform_data.download_package.output

  role_name                 = var.create_role ? var.name : null
  role_permissions_boundary = var.role_permissions_boundary
  timeout                   = var.lambda_timeout
  create_package            = false
  publish                   = true
  create_role               = var.create_role
  lambda_role               = var.create_role ? "" : var.role_arn

  environment_variables = {
    KOSLI_COMMANDS                     = join(";", local.kosli_commands)
    KOSLI_HOST                         = var.kosli_host
    KOSLI_API_TOKEN_SSM_PARAMETER_NAME = var.kosli_api_token_ssm_parameter_name
    KOSLI_ORG                          = var.kosli_org
  }

  allowed_triggers = local.allowed_triggers_combined

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days

  tags = var.tags
}

locals {
  kosli_commands = [for env in var.environments : format(
    "kosli snapshot %s %s %s %s",
    env.kosli_environment_type,
    env.kosli_environment_name,
    (
      env.kosli_environment_type == "s3" ? format("--bucket %s", env.reported_aws_resource_name) :
      env.kosli_environment_type == "ecs" && env.reported_aws_resource_name != null ? format("--clusters %s", env.reported_aws_resource_name) :
      env.kosli_environment_type == "lambda" && env.reported_aws_resource_name != null ? format("--function-names %s", env.reported_aws_resource_name) :
      ""
    ),
    env.kosli_command_optional_parameters != null ? env.kosli_command_optional_parameters : ""
  )]
}

locals {
  to_be_reported_ecs      = anytrue([for env in var.environments : env.kosli_environment_type == "ecs"])
  to_be_reported_lambda   = anytrue([for env in var.environments : env.kosli_environment_type == "lambda"])
  to_be_reported_s3       = anytrue([for env in var.environments : env.kosli_environment_type == "s3"])
  reported_s3_bucket_name = [for env in var.environments : env.reported_aws_resource_name if env.kosli_environment_type == "s3"][0]
}
