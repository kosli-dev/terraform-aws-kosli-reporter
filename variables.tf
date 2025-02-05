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
  description = "The Kosli cli version, should be set in format v2.11.5"
  default     = "v2.11.5"
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

variable "kosli_api_token_ssm_parameter_arn" {
  description = "ARN of the Kosli API token SSM parameter. If not set, the 'kosli_api_token' SSM parameter in the current AWS account will be used by default."
  type        = string
  default     = ""
}

variable "kosli_api_token_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt Kosli API token SSM parameter"
  type        = string
  default     = "*"
}

variable "create_default_eventbridge_rules" {
  description = "Controls whether the module should create the default eventbridge rules to trigger the Reporter lambda. There is a rule per environment type - ECS, Lambda and S3"
  type        = bool
  default     = false
}

variable "use_custom_eventbridge_patterns" {
  description = "Controls whether to provide custom patterns for the EventBridge rules that trigger the Reporter Lambda Function. Set to true if you need to provide own event patterns."
  type        = bool
  default     = false
}

variable "custom_eventbridge_patterns" {
  description = "Event patterns described as a list of JSON objects."
  type        = list(string)
  default     = null
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
