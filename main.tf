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
  role_path                 = var.role_path
  policy_path               = var.policy_path
  timeout                   = var.lambda_timeout
  create_package            = false
  publish                   = true
  create_role               = var.create_role
  lambda_role               = var.create_role ? "" : var.role_arn

  environment_variables = {
    KOSLI_COMMAND                      = local.kosli_command
    KOSLI_HOST                         = var.kosli_host
    KOSLI_API_TOKEN_SSM_PARAMETER_NAME = var.kosli_api_token_ssm_parameter_name
    KOSLI_ORG                          = var.kosli_org
  }

  allowed_triggers = local.allowed_triggers_combined

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days

  tags = var.tags
}

# Prepare Kolsi report command
locals {
  kosli_command_mandatory_parameter = {
    s3     = " --bucket ${var.reported_aws_resource_name}"
    ecs    = ""
    lambda = ""
  }
  kosli_command_optional_parameters = {
    s3     = var.kosli_command_optional_parameters
    ecs    = var.reported_aws_resource_name == "" ? var.kosli_command_optional_parameters : "--clusters ${var.reported_aws_resource_name} ${var.kosli_command_optional_parameters}"
    lambda = var.reported_aws_resource_name == "" ? var.kosli_command_optional_parameters : "--function-names ${var.reported_aws_resource_name} ${var.kosli_command_optional_parameters}"
  }
  kosli_command_mandatory = "kosli snapshot ${var.kosli_environment_type} ${var.kosli_environment_name}${local.kosli_command_mandatory_parameter[var.kosli_environment_type]}"
  kosli_command           = local.kosli_command_optional_parameters == "" ? local.kosli_command_mandatory : "${local.kosli_command_mandatory} ${local.kosli_command_optional_parameters[var.kosli_environment_type]}"
}
