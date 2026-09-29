provider "aws" {
  region = "eu-central-1"
}

module "lambda_reporter" {
  # Published users: source = "kosli-dev/kosli-reporter/aws", version = "0.11.0" or later.
  source = "../../"

  name      = "kosli-reporter"
  kosli_org = "my_org"

  kosli_api_token_secret_arn  = "arn:aws:secretsmanager:eu-central-1:111122223333:secret:kosli_api_token-AbCdEf"
  kosli_api_token_kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"

  vpc_subnet_ids         = ["subnet-00000000000000000"]
  vpc_security_group_ids = ["sg-00000000000000000"]

  extra_environment_variables = {
    HTTPS_PROXY = "http://proxy.example.internal:3128"
    NO_PROXY    = "amazonaws.com"
  }

  environments = [
    {
      kosli_environment_type = "ecs"
      kosli_environment_name = "staging"
    }
  ]
}
