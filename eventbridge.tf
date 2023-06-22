# Cron is default event for all the environment types
resource "aws_cloudwatch_event_rule" "cron_every_minute" {
  name        = "${var.name}-cron"
  description = "Trigger ${var.name} by cron"

  schedule_expression = var.schedule_expression

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "cron" {
  arn       = module.reporter_lambda.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.cron_every_minute.name
  target_id = "${module.reporter_lambda.lambda_function_name}-cron"
}

# In case of reporting ECS environment type also using ECS events. This allows to trigger 
# reporter lambda right after ECS task was updated.
resource "aws_cloudwatch_event_rule" "ecs_task_updated" {
  count       = var.kosli_environment_type == "ecs" ? 1 : 0
  name        = "${var.name}-ecs-task-updated"
  description = "ECS task has been updated"

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Task State Change"]
    detail = {
      clusterArn    = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.reported_aws_resource_name}"]
      desiredStatus = ["RUNNING"]
      lastStatus    = ["RUNNING"]
    }
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "ecs_task_updated" {
  count     = var.kosli_environment_type == "ecs" ? 1 : 0
  arn       = module.reporter_lambda.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.ecs_task_updated[0].name
  target_id = "${var.name}-ecs-task-updated"
}

# Create the default eventbridge pattern if custom one is not provided.
locals {
  lambda_event_pattern = !var.use_custom_eventbridge_pattern && var.create_default_lambda_eventbridge_rule ? jsonencode({
    source      = ["aws.lambda"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      requestParameters = {
        functionName = [{
          prefix = ""
        }]
      }
      responseElements = {
        functionName = [{
          prefix = ""
        }]
      }
    }
  }) : var.custom_eventbridge_pattern
}

resource "aws_cloudwatch_event_rule" "lambda_function_version_published" {
  count       = var.kosli_environment_type == "lambda" && (var.create_default_lambda_eventbridge_rule || var.use_custom_eventbridge_pattern) ? 1 : 0
  name        = "${var.name}-lambda-function-version-published"
  description = "Lambda function version has been published"

  event_pattern = local.lambda_event_pattern
  tags          = var.tags
}

resource "aws_cloudwatch_event_target" "lambda_function_version_published" {
  count     = var.kosli_environment_type == "lambda" && (var.create_default_lambda_eventbridge_rule || var.use_custom_eventbridge_pattern) ? 1 : 0
  arn       = module.reporter_lambda.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.lambda_function_version_published[0].name
  target_id = "${var.name}-lambda-function-version-published"
}

# Trigger reporter lambda right after reported S3 bucket configuration is changed.
resource "aws_cloudwatch_event_rule" "s3_configuration_updated" {
  count       = var.kosli_environment_type == "s3" ? 1 : 0
  name        = "${var.name}-s3-configuration-updated"
  description = "S3 configuragtion has been updated"

  event_pattern = jsonencode({
    source    = ["aws.s3"]
    resources = ["arn:aws:s3:::${var.reported_aws_resource_name}"]
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "s3_configuration_updated" {
  count     = var.kosli_environment_type == "s3" ? 1 : 0
  arn       = module.reporter_lambda.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.s3_configuration_updated[0].name
  target_id = "${var.name}-s3-configuration-updated"
}

# Prepare triggers list
locals {
  trigger_cron = {
    AllowExecutionFromCloudWatchCron = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.cron_every_minute.arn
  } }

  trigger_ecs_task_changed = var.kosli_environment_type == "ecs" ? { AllowExecutionFromCloudWatchECS = {
    principal  = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.ecs_task_updated[0].arn
  } } : {}

  trigger_lambda_new_version_published = var.kosli_environment_type == "lambda" && (var.create_default_lambda_eventbridge_rule || var.use_custom_eventbridge_pattern) ? { AllowExecutionFromCloudWatchLambda = {
    principal  = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.lambda_function_version_published[0].arn
  } } : {}

  trigger_s3_configuration_changed = var.kosli_environment_type == "s3" ? { AllowExecutionFromCloudWatchS3 = {
    principal  = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.s3_configuration_updated[0].arn
  } } : {}

  allowed_triggers_combined = merge(local.trigger_cron, local.trigger_ecs_task_changed, local.trigger_lambda_new_version_published, local.trigger_s3_configuration_changed)
}
