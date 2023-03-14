variable "kosli_environment_type" {
  type = string
  description = "The type of environment. Valid values are: ecs, k8s, lambda, s3."
  validation {
    condition     = contains(["ecs", "lambda"], var.kosli_environment_type)
    error_message = "Wrong kosli_environment_type value. The value must be the one of: ecs, lambda."
  }
}

variable "name" {
  type = string
  description = "The name for the reporter AWS resources."
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
  description = "Where to download the reporter lambda package."
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