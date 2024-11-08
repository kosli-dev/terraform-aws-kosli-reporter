# Cron is mandatory rule regardless of the type of environment
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

# Default eventbridge rule for ECS environment
resource "aws_cloudwatch_event_rule" "ecs_task_updated" {
  count       = local.to_be_reported_ecs && var.create_default_eventbridge_rules ? 1 : 0
  name        = "${var.name}-ecs-task-updated"
  description = "ECS task has been updated"

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Task State Change"]
    detail = {
      clusterArn    = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/*"]
      desiredStatus = ["RUNNING"]
      lastStatus    = ["RUNNING"]
    }
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "ecs_task_updated" {
  count     = local.to_be_reported_ecs && var.create_default_eventbridge_rules ? 1 : 0
  arn       = module.reporter_lambda.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.ecs_task_updated[0].name
  target_id = "${var.name}-ecs-task-updated"
}

# Default eventbridge rule for Lambda environment
locals {
  lambda_event_pattern = jsonencode({
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
  })
}

resource "aws_cloudwatch_event_rule" "lambda_function_version_published" {
  count       = local.to_be_reported_lambda && var.create_default_eventbridge_rules ? 1 : 0
  name        = "${var.name}-lambda-function-version-published"
  description = "Lambda function version has been published"

  event_pattern = local.lambda_event_pattern
  tags          = var.tags
}

resource "aws_cloudwatch_event_target" "lambda_function_version_published" {
  count     = local.to_be_reported_lambda && var.create_default_eventbridge_rules ? 1 : 0
  arn       = module.reporter_lambda.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.lambda_function_version_published[0].name
  target_id = "${var.name}-lambda-function-version-published"
}

# Default eventbridge rule for S3 environment
resource "aws_cloudwatch_event_rule" "s3_configuration_updated" {
  count       = local.to_be_reported_s3 && var.create_default_eventbridge_rules ? 1 : 0
  name        = "${var.name}-s3-configuration-updated"
  description = "S3 configuragtion has been updated"

  event_pattern = jsonencode({
    source    = ["aws.s3"]
    resources = ["arn:aws:s3:::${local.reported_s3_bucket_name}"]
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "s3_configuration_updated" {
  count     = local.to_be_reported_s3 && var.create_default_eventbridge_rules ? 1 : 0
  arn       = module.reporter_lambda.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.s3_configuration_updated[0].name
  target_id = "${var.name}-s3-configuration-updated"
}

# Custom eventbridge rule
resource "aws_cloudwatch_event_rule" "custom" {
  count       = var.use_custom_eventbridge_pattern ? 1 : 0
  name        = "${var.name}-custom"
  description = "${var.name} Eventbridge rule provided by user"

  event_pattern = var.custom_eventbridge_pattern
  tags          = var.tags
}

resource "aws_cloudwatch_event_target" "custom" {
  count     = var.use_custom_eventbridge_pattern ? 1 : 0
  arn       = module.reporter_lambda.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.custom[0].name
  target_id = "${var.name}-custom"
}

# Prepare triggers list
locals {
  trigger_cron = {
    AllowExecutionFromCloudWatchCron = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.cron_every_minute.arn
    }
  }

  trigger_ecs_task_changed = local.to_be_reported_ecs && var.create_default_eventbridge_rules ? { AllowExecutionFromCloudWatchECS = {
    principal  = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.ecs_task_updated[0].arn
    }
  } : {}

  trigger_lambda_new_version_published = local.to_be_reported_lambda && var.create_default_eventbridge_rules ? { AllowExecutionFromCloudWatchLambda = {
    principal  = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.lambda_function_version_published[0].arn
    }
  } : {}

  trigger_s3_configuration_changed = local.to_be_reported_s3 && var.create_default_eventbridge_rules ? { AllowExecutionFromCloudWatchS3 = {
    principal  = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.s3_configuration_updated[0].arn
    }
  } : {}

  trigger_custom = var.use_custom_eventbridge_pattern ? { AllowExecutionCustom = {
    principal  = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.custom[0].arn
    }
  } : {}

  allowed_triggers_combined = merge(
    local.trigger_cron, 
    local.trigger_ecs_task_changed, 
    local.trigger_lambda_new_version_published, 
    local.trigger_s3_configuration_changed,
    local.trigger_custom
  )
}