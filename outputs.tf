output "kosli_commands" {
  value = local.kosli_commands

  # Checks that span two variables; validation blocks can only do this from Terraform 1.9.
  # They sit on an output, not a data source, so they don't delay any data source read.
  precondition {
    condition     = var.kosli_api_token_secret_arn == "" || var.kosli_api_token_ssm_parameter_arn == ""
    error_message = "Set only one of kosli_api_token_secret_arn and kosli_api_token_ssm_parameter_arn."
  }
  precondition {
    condition     = (length(var.vpc_subnet_ids) > 0) == (length(var.vpc_security_group_ids) > 0)
    error_message = "Set both vpc_subnet_ids and vpc_security_group_ids, or neither."
  }
}
