module "reporter_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.7.0"

  attach_policy_json = true
  policy_json        = var.create_role ? data.aws_iam_policy_document.combined[0].json : null

  function_name = var.name
  description   = var.lambda_description
  handler       = "main.lambda_handler"
  runtime       = "python3.11"

  role_name                 = var.create_role ? var.name : null
  role_permissions_boundary = var.role_permissions_boundary
  role_path                 = var.role_path
  policy_path               = var.policy_path
  timeout                   = var.lambda_timeout
  create_package            = true
  publish                   = true
  create_role               = var.create_role
  lambda_role               = var.create_role ? "" : var.role_arn

  layers = [
    local.kosli_cli_layer_arn
  ]

  source_path = [
    {
      path = "${path.module}/deployment/reporter-lambda-src"
      commands = [
        ":zip"
      ]
    }
  ]

  environment_variables = {
    KOSLI_COMMANDS                    = join(";", local.kosli_commands)
    KOSLI_HOST                        = var.kosli_host
    KOSLI_API_TOKEN_SSM_PARAMETER_ARN = local.kosli_api_token_ssm_parameter_arn
    KOSLI_ORG                         = var.kosli_org
  }

  allowed_triggers = local.allowed_triggers_combined

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days

  tags = var.tags
}

provider "aws" {
  alias  = "eu_central_1"
  region = "eu-central-1"
}

data "aws_s3_object" "cli_to_layer_mapping" {
  bucket   = "lambda-layer-mapping-ccc19615fd6c05ace42e71c551995458dbdb1be7"
  key      = "lambda_layer_versions.json"
  provider = aws.eu_central_1
}

locals {
  kosli_cli_layer_arn = jsondecode(data.aws_s3_object.cli_to_layer_mapping.body)[var.kosli_cli_version][data.aws_region.current.name]
}

locals {
  kosli_commands = [for env in var.environments : format(
    "kosli snapshot %s %s%s%s",
    env.kosli_environment_type,
    env.kosli_environment_name,
    (
      env.kosli_environment_type == "s3" ? format(" --bucket %s", env.reported_aws_resource_name) :
      env.kosli_environment_type == "ecs" && env.reported_aws_resource_name != null ? format(" --clusters %s", env.reported_aws_resource_name) :
      env.kosli_environment_type == "lambda" && env.reported_aws_resource_name != null ? format(" --function-names %s", env.reported_aws_resource_name) :
      ""
    ),
    env.kosli_command_optional_parameters != null ? " ${env.kosli_command_optional_parameters}" : ""
  )]
}

locals {
  to_be_reported_ecs    = anytrue([for env in var.environments : env.kosli_environment_type == "ecs"])
  to_be_reported_lambda = anytrue([for env in var.environments : env.kosli_environment_type == "lambda"])
  to_be_reported_s3     = anytrue([for env in var.environments : env.kosli_environment_type == "s3"])
}

# If the kosli_api_token_ssm_parameter_arn variable is not set, the "kosli_api_token" SSM parameter in the current AWS account is used by default.
locals {
  kosli_api_token_ssm_parameter_arn = var.kosli_api_token_ssm_parameter_arn == "" ? "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/kosli_api_token" : var.kosli_api_token_ssm_parameter_arn
}
