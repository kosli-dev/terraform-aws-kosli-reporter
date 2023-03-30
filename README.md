# Kosli Reporter
Terraform module to deploy the Kosli reporter - AWS lambda function that sends reports to the Kosli. At the moment module supports only reports of ECS and Lambda environment types.

## Set up Kolsi API token
1. Log in to the https://app.kosli.com/, go to your profile, copy the `API Key` value.
2. Put the Kosli API key value to the AWS SSM parameter (SecureString type). By default, Lambda Reporter will serch for the `kosli_api_token` SSM parameter name, but it is also possible to set custom parameter name (use `kosli_api_token_ssm_parameter_name` variable).

## Usage
```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.1.0"

  name                       = "production_app"
  kosli_environment_type     = "ecs"
  kosli_cli_version          = "v2.0.0"
  kosli_environment_name     = "production"
  reported_aws_resource_name = "app"
}
```

## IAM
### Set custom IAM policy
By default Reporter module creates IAM policies to allow Lambda function to access the reported environments. Also possible to provide the custom IAM policy:

```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.1.0"

  name                       = "staging_app"
  kosli_environment_type     = "lambda"
  kosli_cli_version          = "v2.0.0"
  kosli_environment_name     = "staging"
  reported_aws_resource_name = "my-lambda-function"
  use_custom_policy          = true
  custom_policy_json         = data.aws_iam_policy_document.this.json
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

### Set custom IAM role
Also it is possible to provide custom IAM role. You need to disable default role creation by setting the parameter `create_role` to `false` and providing custom role ARN with parameter `role_arn`:

```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.1.0"

  name                       = "staging_app"
  kosli_environment_type     = "s3"
  kosli_cli_version          = "v2.0.0"
  kosli_environment_name     = "staging"
  reported_aws_resource_name = "my-s3-bucket"
  role_arn                   = aws_iam_role.this.arn
  create_role                = false
}
```

## Kosli report command
- The Kosli cli report command that is executed inside the Repoter Lambda function can be obtained by accessing `kosli_command` module output. 
- Optional Kosli cli parameters can be added to the command with the `kosli_command_optional_parameters` module parameter.

```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.1.0"

  name                              = "staging_app"
  kosli_environment_type            = "lambda"
  kosli_cli_version                 = "v2.0.0"
  kosli_environment_name            = "staging"
  reported_aws_resource_name        = "my-lambda-function"
  kosli_command_optional_parameters = "--function-version 2"
}

output "kosli_command" {
  value = module.lambda_reporter.kosli_command
}
```

Terraform output:
```
Outputs:

kosli_command = "kosli snapshot lambda staging --function-name my-lambda-function --function-version 2"
```