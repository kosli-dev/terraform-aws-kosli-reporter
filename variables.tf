variable "environments" {
  description = "A list of maps that represents the environments to be reported to Kosli."
  type = list(object({
    kosli_environment_name            = string
    kosli_environment_type            = string           # ecs, lambda or s3
    reported_aws_resource_name        = optional(string) # The name of the reported AWS resource name(s). For the ECS environment, this refers to the name(s) of the ECS cluster; for the S3 environment, the S3 bucket name; and for the Lambda environment, the Lambda function name(s).
    kosli_command_optional_parameters = optional(string) # The optional parameters to add to the kosli report command
  }))
}

variable "kosli_org" {
  type        = string
  description = "Kosli organisation name (the value for the cli --org parameter)."
}

variable "name" {
  type        = string
  description = "The name for the Reporter AWS resources."
}

variable "kosli_cli_version" {
  type        = string
  description = "The Kosli cli version, should be set in format v2.14.0"
}

variable "tags" {
  type        = map(string)
  description = "Tags to assign to the reporter AWS resources."
  default     = {}
}

variable "kosli_host" {
  type        = string
  default     = "https://app.kosli.com"
  description = "The Kosli endpoint."
}

variable "cloudwatch_logs_retention_in_days" {
  type        = number
  default     = 7
  description = "The retention period of reporter logs (days)."
}

variable "schedule_expression" {
  type        = string
  default     = "rate(1 minute)"
  description = "The scheduling expression. For example, cron(0 20 * * ? *) or rate(5 minutes). For more information, refer to the AWS documentation https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html"
}

variable "create_role" {
  description = "Controls whether IAM role for Reporter Lambda Function should be created. Set to false if you need to provide own IAM role"
  type        = bool
  default     = true
}

variable "role_arn" {
  description = "IAM role ARN attached to the Reporter Lambda Function. This governs both who / what can invoke your Lambda Function, as well as what resources our Lambda Function has access to."
  type        = string
  default     = ""
}

variable "role_permissions_boundary" {
  description = "The ARN of the policy that is used to set the permissions boundary for the IAM role used by Lambda Function"
  type        = string
  default     = null
}

variable "kosli_api_token_ssm_parameter_name" {
  description = "The name of the kosli_api_token SSM parameter name"
  type        = string
  default     = "kosli_api_token"
}

variable "create_default_eventbridge_rules" {
  description = "Controls whether the module should create the default eventbridge rules to trigger the Reporter lambda. There is a rule per environment type - ECS, Lambda and S3"
  type        = bool
  default     = true
}

variable "use_custom_eventbridge_pattern" {
  description = "Controls whether to provide custom pattern for the eventbridge rule, that triggers the Reporter Lambda Function. Set to true if you need to provide own event pattern."
  type        = bool
  default     = false
}

variable "custom_eventbridge_pattern" {
  description = "Event pattern described a JSON object."
  type        = string
  default     = null
}

variable "always_download_kosli_bin" {
  description = "Controls whether to download Kosli bin on every terraform run for preparing the Reporter lambda package. Could be useful in CI."
  type        = bool
  default     = false
}

variable "reporter_releases_host" {
  type        = string
  default     = "https://reporter-releases.kosli.com"
  description = "Where to download the Reporter Lambda package."
}

variable "lambda_timeout" {
  type        = number
  default     = 60
  description = "The amount of time Reporter Lambda Function has to run in seconds."
}

variable "lambda_description" {
  type        = string
  default     = "Send reports to the Kosli app"
  description = "Lambda function description."
}
