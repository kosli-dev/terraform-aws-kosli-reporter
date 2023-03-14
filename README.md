# Kosli Reporter
Terraform module to deploy the Kosli reporter - AWS lambda function that sends reports to the Kosli. At the moment module supports only reports of ECS and Lambda environment types.

## Steps to deploy Kosli-reporter
1. Add `kosli_api_token` AWS SSM parameter
2. An example of terraform specs:
```
module "lambda_reporter" {
  source  = "kosli-dev/kosli-reporter/aws"
  version = "0.0.7"

  name                   = "production_app"
  kosli_environment_type = "ecs"
  kosli_host             = "https://app.kosli.com"
  kosli_cli_version      = "v0.1.41"
  kosli_command          = "kosli environment report ecs production -C app --owner my_organisation"
  ecs_cluster_name       = "app"
}
```
