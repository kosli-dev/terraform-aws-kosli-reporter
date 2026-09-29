# Kosli Reporter Terraform module

Terraform module to deploy the Kosli environment reporter as an AWS lambda function. At the moment, the module only supports reporting of ECS, Lambda and S3 environment types.

# AWS Provider Version

From `v0.9.0` onwards, the Kosli Reporter module requires `v6` of the Terraform AWS Provider.
If you are running version `v5`, you will need to select `v0.8.2` of Kosli Reporter module.

## In order to deploy the Kosli reporter module, you will need to do the following:

1. Set up Kosli API token:
  - Login to Kosli and [generate a new service account and API key](https://docs.kosli.com/getting_started/service-accounts/)
  - Store the Kosli API key value in an AWS SSM parameter (SecureString type). By default, Lambda Reporter will search for the `kosli_api_token` SSM parameter in the current AWS account, but it is also possible to set custom parameter arn (use `kosli_api_token_ssm_parameter_arn` variable).
  - Or store it in AWS Secrets Manager instead (see [Read the API token from AWS Secrets Manager](#read-the-api-token-from-aws-secrets-manager)).

2. Install Terraform: If you haven't already, you'll need to install Terraform on your local machine. You can download Terraform from the [official website](https://www.terraform.io/downloads.html).

3. Configure your AWS credentials: Terraform needs access to your AWS account to be able to manage your resources. You can set up your AWS credentials by following the instructions in the [AWS documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)

4. Create a Terraform configuration: In order to use the Kosli reporter module, you'll need to create a Terraform configuration. There are configuration examples ([see here](https://github.com/kosli-dev/terraform-aws-kosli-reporter/tree/main/examples)) that will track ECS cluster, S3 bucket and Lambda functions - `lambda-report-all`, which will report all Lambda functions in the region and `lambda-report-selectively`, which reports only selected functions.

5. Initialize and run Terraform: Once Terraform configuration is created, you'll need to initialize Terraform by running the `terraform init` command in the same directory as your configuration files. This will download the necessary modules and providers for your configuration. Then, you can run the `terraform apply` command to apply your configuration.

6. To check Lambda reporter logs you can go to the AWS console -> Lambda service -> choose your lambda reporter function -> Monitor tab -> Logs tab.

## Report multiple environments

It is possible to track multiple environments with a single Kosli reporter.

```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "~> 0.11"

  name              = "kosli-reporter"
  kosli_cli_version = "v2.28.0"
  kosli_org         = "my-organisation"
  # kosli_host        = "https://app.kosli.com" # defaulted to app.kosli.com
  environments = [
    {
      kosli_environment_name = "staging-ecs"
      kosli_environment_type = "ecs"
    },
    {
      kosli_environment_name     = "staging-s3"
      kosli_environment_type     = "s3"
      reported_aws_resource_name = "my-bucket"
    },
    {
      kosli_environment_name = "staging-lambda"
      kosli_environment_type = "lambda"
    }
  ]
}
```

## Set custom IAM role

It is possible to provide custom IAM role. In this case you need to disable default role creation by setting the parameter `create_role` to `false` and providing custom role ARN with parameter `role_arn`:

```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "~> 0.11"

  name                       = "kosli-reporter"
  kosli_cli_version          = "v2.33.2"
  kosli_org                  = "my-organisation"
  # kosli_host                 = "https://app.kosli.com" # defaults to app.kosli.com
  role_arn                   = aws_iam_role.this.arn
  create_role                = false
  environments = [
    {
      kosli_environment_name     = "staging-s3"
      kosli_environment_type     = "s3"
      reported_aws_resource_name = "my-s3-bucket"
    }
  ]
}

resource "aws_iam_role" "this" {
  name               = "staging_reporter"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })
}
```

## Read the API token from AWS Secrets Manager

Set `kosli_api_token_secret_arn` to the secret's full ARN, including the six-character suffix AWS adds. This replaces the SSM parameter, so leave `kosli_api_token_ssm_parameter_arn` unset: setting both fails at plan time. Store the token as a plain string secret. The ARN must be known at plan time: a literal or a data source, not a secret created in the same apply.

The module's role gets `secretsmanager:GetSecretValue` on that secret, and `kms:Decrypt` on `kosli_api_token_kms_key_arn` only when the call comes through Secrets Manager in the secret's region. With `create_role = false`, give your own role those two permissions.

If the secret is in another AWS account, the module cannot set that up for you. You need:
- a resource policy on the secret that allows the reporter's role to call `secretsmanager:GetSecretValue`
- the secret encrypted with a customer-managed KMS key whose key policy allows the reporter's role `kms:Decrypt` (the default `aws/secretsmanager` key cannot be used from another account)
- `kosli_api_token_kms_key_arn` set to that key's ARN

## Run the reporter in a VPC behind a proxy

Set `vpc_subnet_ids` and `vpc_security_group_ids` together; setting only one fails at plan time. The module gives its role the network interface permissions Lambda needs inside a VPC. With `create_role = false`, attach `AWSLambdaVPCAccessExecutionRole` or equivalent to your own role. The subnets need a route to your Kosli host and to the AWS APIs the reporter reads.

Use `extra_environment_variables` for proxy settings. Both the Lambda code (boto3) and the Kosli CLI read them. Putting `amazonaws.com` in `NO_PROXY` sends AWS API calls direct, for example through VPC endpoints, and only Kosli traffic through the proxy:

```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "~> 0.11"

  name      = "kosli-reporter"
  kosli_org = "my-organisation"

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
      kosli_environment_name = "staging-ecs"
      kosli_environment_type = "ecs"
    }
  ]
}
```

`extra_environment_variables` cannot set the variables the module sets itself (`KOSLI_COMMANDS`, `KOSLI_HOST`, `KOSLI_ORG`, `KOSLI_API_TOKEN`, `KOSLI_API_TOKEN_SSM_PARAMETER_ARN`, `KOSLI_API_TOKEN_SECRET_ARN`); that fails at plan time. Other `KOSLI_*` variables, such as `KOSLI_DEBUG`, are passed to the CLI.

## Kosli reporter triggers

The Kosli reporter sends reports to Kosli every minute by default. You can customize the schedule using the `schedule_expression` parameter.

If you need to send reports more frequently, you can enable the creation of default EventBridge rules by setting the `create_default_eventbridge_rules` parameter to `true`. These default rules capture any changes to *any resource of the specified type* in the AWS region. For example, if you are tracking a single S3 bucket, the default rule will trigger the Kosli reporter whenever any S3 bucket in the region changes. This behavior might result in overly frequent triggers, making custom EventBridge rules a better alternative in some cases.

To use a custom EventBridge rule, set the `use_custom_eventbridge_patterns` parameter to `true` and specify the desired patterns using the `custom_eventbridge_patterns` parameter. This example demonstrates how to trigger the Kosli reporter immediately after any of the reported Lambda functions change or any of the tasks in the reported ECS clusters change.

```
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

variable "my_lambda_functions" {
  type    = string
  default = "my_lambda_function1,my_lambda_function2"
}

variable "my_ecs_clusters" {
  type    = string
  default = "my_ecs_cluster1,my_ecs_cluster2"
}

module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "~> 0.11"

  name                             = "kosli-reporter"
  kosli_cli_version                = "v2.33.2"
  kosli_org                        = "my-organisation"
  # kosli_host                       = "https://app.kosli.com" # defaulted to app.kosli.com
  use_custom_eventbridge_patterns  = true
  custom_eventbridge_patterns      = [
    local.lambda_event_pattern,
    local.ecs_event_pattern
  ]

  environments = [
    {
      kosli_environment_type     = "lambda"
      kosli_environment_name     = "staging"
      reported_aws_resource_name = var.my_lambda_functions
    },
    {
      kosli_environment_type = "ecs"
      kosli_environment_name = "staging"
      reported_aws_resource_name = var.my_ecs_clusters
    }
  ]
}

locals {
  lambda_function_names_list = split(",", var.my_lambda_functions)
  ecs_cluster_names_list = split(",", var.my_ecs_clusters)

  lambda_event_pattern = jsonencode({
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
  ecs_event_pattern = jsonencode(
  {
    source      = ["aws.ecs"]
    detail-type = ["ECS Task State Change"]
    detail = {
      clusterArn    = [for cluster in local.ecs_cluster_names_list : "arn:aws:ecs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:cluster/${cluster}"]
      desiredStatus = ["RUNNING"]
      lastStatus    = ["RUNNING"]
    }
  })
}
```

## Kosli report command

- The Kosli cli report commands that are executed inside the Reporter Lambda function can be obtained by accessing `kosli_commands` module output.
- Optional Kosli cli parameters can be added to the command with the `kosli_command_optional_parameters` module parameter.

```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "~> 0.11"

  name                   = "kosli-reporter"
  kosli_cli_version      = "v2.33.2"
  kosli_org              = "my-organisation"
  environments = [
    {
      kosli_environment_name            = "staging-ecs"
      kosli_environment_type            = "ecs"
      kosli_command_optional_parameters = "--exclude another_ecs_cluster" # Exclude cluster with the name "another_ecs_cluster".
    },
    {
      kosli_environment_name     = "staging-lambda"
      kosli_environment_type     = "lambda"
      reported_aws_resource_name = "my-lambda-function" # use a comma-separated list of function names to report multiple functions
    }
  ]
}

output "kosli_commands" {
  value = module.lambda_reporter.kosli_commands
}
```

### Terraform output

```
Outputs:

kosli_commands = [
  "kosli snapshot ecs staging-ecs --exclude another_ecs_cluster",
  "kosli snapshot lambda staging-lambda --function-names my-lambda-function"

]
```
