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
  default = "my_lambda_function1,my_lambda_function2"
}

module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.8.0"

  name              = local.reporter_name
  kosli_cli_version = "v2.11.6"
  kosli_org         = "my_org"
  # kosli_host        = "https://app.kosli.com" # defaulted to app.kosli.com
  use_custom_eventbridge_patterns = true
  custom_eventbridge_patterns     = local.custom_event_pattern

  environments = [
    {
      kosli_environment_type     = "lambda"  # Mandatory parameter
      kosli_environment_name     = "staging" # Mandatory parameter
      reported_aws_resource_name = var.my_lambda_functions
    }
  ]
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
