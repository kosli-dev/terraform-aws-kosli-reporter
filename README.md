# Kosli Reporter
Terraform module to deploy the Kosli environment reporter as an AWS lambda function. At the moment, the module only supports reporting of ECS, Lambda and S3 environment types.

## In order to deploy the Kosli reporter module, you will need to do the following:

1. Set up Kosli API token:
  - Login to Kosli and [generate a new service account and API key](https://docs.kosli.com/getting_started/service-accounts/)
  - Store the Kosli API key value in an AWS SSM parameter (SecureString type). By default, Lambda Reporter will search for the `kosli_api_token` SSM parameter, but it is also possible to set custom parameter name (use `kosli_api_token_ssm_parameter_name` variable).

2. Install Terraform: If you haven't already, you'll need to install Terraform on your local machine. You can download Terraform from the [official website](https://www.terraform.io/downloads.html).

3. Configure your AWS credentials: Terraform needs access to your AWS account to be able to manage your resources. You can set up your AWS credentials by following the instructions in the [AWS documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)

4. Create a Terraform configuration: In order to use the Kosli reporter module, you'll need to create a Terraform configuration. There are configuration examples ([see here](https://github.com/kosli-dev/terraform-aws-kosli-reporter/tree/master/examples)) that will track ECS cluster, S3 bucket and Lambda functions - `lambda-report-all`, which will report all Lambda functions in the region and `lambda-report-selectively`, which reports only selected functions.

5. Initialize and run Terraform: Once Terraform configuration is created, you'll need to initialize Terraform by running the `terraform init` command in the same directory as your configuration files. This will download the necessary modules and providers for your configuration. Then, you can run the `terraform apply` command to apply your configuration.

6. To check Lambda reporter logs you can go to the AWS console -> Lambda service -> choose your lambda reporter function -> Monitor tab -> Logs tab.

## Report multiple environments
It is possible to track multiple environments with a single Kosli reporter.

```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.7.0"

  name              = "kosli-reporter"
  kosli_cli_version = "v2.14.0"
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
  version = "0.7.0"

  name                       = "kosli-reporter"
  kosli_cli_version          = "v2.14.0"
  kosli_org                  = "my-organisation"
  # kosli_host                 = "https://app.kosli.com" # defaulted to app.kosli.com
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

## Kosli reporter triggers
The Kosli reporter sends reports to Kosli every minute by default. You can customize the schedule using the `schedule_expression` parameter.

If you need to send reports more frequently, you can enable the creation of default EventBridge rules by setting the `create_default_eventbridge_rules` parameter to `true`. These default rules capture any changes to *any resource of the specified type* in the AWS region. For example, if you are tracking a single S3 bucket, the default rule will trigger the Kosli reporter whenever any S3 bucket in the region changes. This behavior might result in overly frequent triggers, making custom EventBridge rules a better alternative in some cases.

To use a custom EventBridge rule, set the `use_custom_eventbridge_pattern` parameter to `true` and specify the desired rule using the `custom_eventbridge_pattern` parameter. This example demonstrates how to trigger the Kosli reporter immediately after any of the reported functions change.

```
variable "my_lambda_functions" {
  type    = string
  default = "my_lambda_function1,my_lambda_function2"
}

module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.7.0"

  name                             = local.reporter_name
  kosli_cli_version                = "v2.14.0"
  kosli_org                        = "my-organisation"
  # kosli_host                       = "https://app.kosli.com" # defaulted to app.kosli.com
  create_default_eventbridge_rules = false
  use_custom_eventbridge_pattern   = true
  custom_eventbridge_pattern       = local.custom_event_pattern
  
  environments = [
    {
      kosli_environment_type     = "lambda"
      kosli_environment_name     = "staging"
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
```

## Kosli report command
- The Kosli cli report commands that are executed inside the Reporter Lambda function can be obtained by accessing `kosli_commands` module output. 
- Optional Kosli cli parameters can be added to the command with the `kosli_command_optional_parameters` module parameter.

```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.7.0"

  name                   = "kosli-reporter"
  kosli_cli_version      = "v2.14.0"
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

Terraform output:
```
Outputs:

kosli_commands = [
  "kosli snapshot ecs staging-ecs --exclude another_ecs_cluster",
  "kosli snapshot lambda staging-lambda --function-names my-lambda-function"

]
```
