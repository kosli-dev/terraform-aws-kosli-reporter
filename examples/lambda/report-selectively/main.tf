provider "aws" {
  region = local.region

  # Make it faster by skipping something
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

locals {
  reporter_name = "reporter-${random_pet.this.id}"
  region        = "eu-central-1"
}

data "aws_caller_identity" "current" {}

data "aws_canonical_user_id" "current" {}

resource "random_pet" "this" {
  length = 2
}

variable "my_lambda_functions" {
  type    = string
  default = "my_lambda_function1, my_lambda_function_name2"
}

module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.4.0"

  name                           = local.reporter_name
  kosli_environment_type         = "lambda"
  kosli_cli_version              = "2.5.0"
  kosli_environment_name         = "staging"
  kosli_org                      = "my_org"
  reported_aws_resource_name     = var.my_lambda_functions
  use_custom_eventbridge_pattern = true
  custom_eventbridge_pattern     = local.custom_event_pattern
}

locals {
  lambda_function_names_list = split(",", var.my_lambda_functions)

  custom_event_pattern = jsonencode({
    source      = ["aws.lambda"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      requestParameters = {
        functionName = local.lambda_function_names_list
      }
      responseElements = {
        functionName = local.lambda_function_names_list
      }
    }
  })
}