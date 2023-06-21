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

module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.3.0"

  name                       = local.reporter_name
  kosli_environment_type     = "lambda"
  kosli_cli_version          = "2.4.1"
  kosli_environment_name     = "staging"
  kosli_org                  = "my_org"
  reported_aws_resource_name = "my_lambda_function" # use a comma-separated list of function names to report multiple functions 
}
