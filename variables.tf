variable "kosli_environment_type" {
  type = string
  description = "The type of environment. Valid values are: ecs, lambda."
  validation {
    condition     = contains(["ecs", "lambda"], var.kosli_environment_type)
    error_message = "Wrong kosli_environment_type value. The value must be the one of: ecs, lambda."
  }
}

variable "name" {
  type = string
  description = "The name for the Reporter AWS resources."
}

variable "kosli_cli_version" {
  type = string
  description = "The Kosli cli version, should be set in format v0.1.41"
}

variable "tags" {
  type = map(string)
  description = "Tags to assign to the reporter AWS resources."
  default = {}
}

variable "kosli_command" {
  type        = string
  default     = ""
  description = "Command to report the status of runtime environment to the Kosli"
}

variable "kosli_host" {
  type        = string
  default     = "https://app.kosli.com"
  description = "The Kosli endpoint."
}

variable "reporter_releases_host" {
  type    = string
  default = "https://reporter-releases.kosli.com"
  description = "Where to download the Reporter Lambda package."
}

variable "ecs_cluster_name" {
  type        = string
  default     = ""
  description = "The name of the ECS cluster."
}

variable "cloudwatch_logs_retention_in_days" {
  type    = number
  default = 7
  description = "The retention period of reporter logs (days)."
}

variable "schedule_expression" {
  type    = string
  default = "rate(1 minute)"
  description = "The scheduling expression. For example, cron(0 20 * * ? *) or rate(5 minutes). For more information, refer to the AWS documentation https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html"
}

variable "use_custom_policy" {
  description = "Controls whether custom policy should be added to IAM role instaed of default module policy"
  type        = bool
  default     = false
}

variable "custom_policy_json" {
  description = "A custom policy document as JSON to attach to the Reporter Lambda Function role"
  type        = string
  default     = null
}

variable "kosli_api_token_ssm_parameter_name" {
  description = "The name of the kosli_api_token SSM parameter name"
  type        = string
  default     = "kosli_api_token"
}
