# Kosli Reporter
Terraform module to deploy the Kosli environment reporter as an AWS lambda function. At the moment, the module only supports reporting of ECS, Lambda and S3 environment types.

## In order to deploy the Kosli reporter module, you will need to do the following:

1. Set up Kosli API token:
  - Login to Kosli and [generate a new service account and API key](https://docs.kosli.com/getting_started/service-accounts/)
  - Store the Kosli API key value in an AWS SSM parameter (SecureString type). By default, Lambda Reporter will search for the `kosli_api_token` SSM parameter, but it is also possible to set custom parameter name (use `kosli_api_token_ssm_parameter_name` variable).

2. Install Terraform: If you haven't already, you'll need to install Terraform on your local machine. You can download Terraform from the [official website](https://www.terraform.io/downloads.html).

3. Configure your AWS credentials: Terraform needs access to your AWS account to be able to manage your resources. You can set up your AWS credentials by following the instructions in the [AWS documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)

4. Create a Terraform configuration: In order to use the Kosli reporter module, you'll need to create a Terraform configuration. Here are configuration examples that will track [ECS](./examples/ecs), [Lambda](./examples/lambda), [S3](./examples/s3) resources.

5. Initialize and run Terraform: Once Terraform configuration is created, you'll need to initialize Terraform by running the `terraform init` command in the same directory as your configuration files. This will download the necessary modules and providers for your configuration. Then, you can run the `terraform apply` command to apply your configuration.

6. To check Lambda reporter logs you can go to the AWS console -> Lambda service -> choose your lambda reporter function -> Monitor tab -> Logs tab.

## Set custom IAM role
It is possible to provide custom IAM role. In this case you need to disable default role creation by setting the parameter `create_role` to `false` and providing custom role ARN with parameter `role_arn`:

```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.5.0"

  name                       = "staging_app"
  kosli_environment_type     = "s3"
  kosli_cli_version          = "v2.7.8"
  kosli_environment_name     = "staging"
  kosli_org                  = "my-organisation"
  # kosli_host                 = "https://app.kosli.com" # defaulted to app.kosli.com
  reported_aws_resource_name = "my-s3-bucket"
  role_arn                   = aws_iam_role.this.arn
  create_role                = false
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

## Kosli report command
- The Kosli cli report command that is executed inside the Reporter Lambda function can be obtained by accessing `kosli_command` module output. 
- Optional Kosli cli parameters can be added to the command with the `kosli_command_optional_parameters` module parameter.

```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.5.0"

  name                              = "staging_app"
  kosli_environment_type            = "lambda"
  kosli_cli_version                 = "v2.7.8"
  kosli_environment_name            = "staging"
  kosli_org                         = "my-organisation"
  reported_aws_resource_name        = "my-lambda-function" # use a comma-separated list of function names to report multiple functions
}

output "kosli_command" {
  value = module.lambda_reporter.kosli_command
}
```

Terraform output:
```
Outputs:

kosli_command = "kosli snapshot lambda staging --function-names my-lambda-function"
```
