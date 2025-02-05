provider "aws" {
  region = local.region

  # Make it faster by skipping something
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

data "aws_caller_identity" "current" {}

data "aws_canonical_user_id" "current" {}

resource "random_pet" "this" {
  length = 2
}

locals {
  reporter_name = "reporter-${random_pet.this.id}"
  region        = "eu-central-1"
}

module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.8.0"

  name              = local.reporter_name
  kosli_cli_version = "v2.11.6"
  kosli_org         = "my_org"
  # kosli_host        = "https://app.kosli.com" # defaulted to app.kosli.com

  environments = [
    {
      kosli_environment_type = "ecs"     # Mandatory parameter
      kosli_environment_name = "staging" # Mandatory parameter
      # reported_aws_resource_name  = "my_ecs_cluster" # Optional parameter. By default, snapshot all clusters. Uncomment this line to select specific clusters.
      kosli_command_optional_parameters = "--exclude another_ecs_cluster" # Optional parameter. Exclude cluster with the name "another_ecs_cluster".
    }
  ]
}
