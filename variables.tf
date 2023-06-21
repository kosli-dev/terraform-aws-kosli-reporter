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
  description = "The Kosli cli version, should be set in format 2.4.1"
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
  description = "The name of the reported AWS resource name. For the ECS environment - the name of the ECS cluster, S3 environment - S3 bucket name, Lambda environment - Lambda function name."
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

variable "kosli_api_token_ssm_parameter_name" {
  description = "The name of the kosli_api_token SSM parameter name"
  type        = string
  default     = "kosli_api_token"
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