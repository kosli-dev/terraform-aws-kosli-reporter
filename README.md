# Kosli Reporter
Terraform module to deploy the Kosli reporter - AWS lambda function that sends reports to the Kosli. At the moment module supports only reports of ECS and Lambda environment types.

### Set up Kolsi API token
1. Log in to the https://app.kosli.com/, go to your profile, copy the `API Key` value.
2. Put the Kosli API key value to the AWS SSM parameter (SecureString type). By default, Lambda Reporter will serch for the `kosli_api_token` SSM parameter name, but it is also possible to set custom parameter name (use `kosli_api_token_ssm_parameter_name` variable).

### Usage
```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.0.8"

  name                   = "production_app"
  kosli_environment_type = "ecs"
  kosli_host             = "https://app.kosli.com"
  kosli_cli_version      = "v2.0.0"
  kosli_command          = "kosli snapshot ecs production -C app --owner my_organisation"
  ecs_cluster_name       = "app"
}
```

### IAM
By default Reporter module creates IAM policies to allow Lambda function to access the reported environments. Also possible to provide the custom IAM policy:

```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.0.8"

  name                   = "production_app"
  kosli_environment_type = "lambda"
  kosli_host             = "https://app.kosli.com"
  kosli_cli_version      = "v2.0.0"
  kosli_command          = "kosli snapshot lambda staging --function-name my-lambda-function --owner my_organisation"
  use_custom_policy      = true
  custom_policy_json     = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    sid    = "LambdaRead"
    effect = "Allow"
    actions = [
      "lambda:GetFunctionConfiguration"
    ]
    resources = [
      "arn:aws:lambda:eu-central-1:123456789876:function:my-lambda-function"
    ]
  }
}
```
