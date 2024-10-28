variable "kosli_environment_type" {
  type        = string
  description = "The type of environment. Valid values are: ecs, lambda, s3."
  validation {
    condition     = contains(["ecs", "lambda", "s3"], var.kosli_environment_type)
    error_message = "Wrong kosli_environment_type value. The value must be the one of: ecs, lambda, s3."
  }
}

variable "kosli_environment_name" {
  type        = string
  description = "The name of the Kosli environment."
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
  description = "The Kosli cli version, should be set in format v2.5.0"
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

variable "reported_aws_resource_name" {
  type        = string
  default     = ""
  description = "The name of the reported AWS resource name. For the ECS environment - the name of the ECS cluster, S3 environment - S3 bucket name, Lambda environment - Lambda function name(s)."
}

variable "kosli_command_optional_parameters" {
  type        = string
  default     = ""
  description = "The optional parameters to add to the kosli report command, for example when reporting ECS environment type it could be '-s my-service'."
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

variable "role_path" {
  description = "Path of IAM role to use for Lambda Function"
  type        = string
  default     = null
}

variable "policy_path" {
  description = "Path of policies to that should be added to IAM role for Lambda Function"
  type        = string
  default     = null
}

variable "kosli_api_token_ssm_parameter_name" {
  description = "The name of the kosli_api_token SSM parameter name"
  type        = string
  default     = "kosli_api_token"
}

variable "create_default_lambda_eventbridge_rule" {
  description = "Controls whether the module should create the default eventbridge rule to trigger the Reporter lambda. The default rule is configured to trigger Reporter on every change in any lambda function in your AWS region."
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
