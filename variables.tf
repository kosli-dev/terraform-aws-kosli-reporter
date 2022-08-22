variable "kosli_env" {
  type = string
  description = "Kosli environment name."
}

variable "name" {
  type = string
  description = "The name to use for the reporter AWS resources."
}

variable "kosli_cli_version" {
  type = string
  description = "The Kosli cli version, should be set in format v0.1.8"
}

variable "tags" {
  type = map(string)
  description = "Tags to assign to the reporter AWS resources."
  default = {}
}

variable "kosli_host" {
  type        = string
  default     = "https://app.kosli.com"
  description = "The Kosli endpoint."
}

variable "reporter_releases_host" {
  type    = string
  default = "https://reporter-releases.kosli.com"
}

variable "ecs_cluster" {
  type        = string
  description = "The name of the ECS cluster."
}

variable "kosli_org" {
  type        = string
  description = "The Kosli user or organization."
}

variable "cloudwatch_logs_retention_in_days" {
  type    = number
  default = 7
}
