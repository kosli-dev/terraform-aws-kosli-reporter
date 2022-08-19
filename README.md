# Kosli Reporter
Terraform module to deploy the Kosli reporter - AWS lambda function that sends reports to the Kosli. At the moment module supports only ECS reports.

## Steps to deploy Kosli-reporter
1. Add `kosli_api_token` AWS SSM parameter
2. An example of terraform specs:
```
module "lambda_reporter" {
  source                 = "kosli-dev/kosli-reporter"
  name                   = "production_app"
  kosli_env              = "production"
  kosli_cli_version      = "v0.1.8"
  ecs_cluster            = "app"
  kosli_org              = "my_organisation"
}
```