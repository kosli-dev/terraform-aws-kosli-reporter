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

# Trigger reporter lambda right after reported lambda function is changed.
resource "aws_cloudwatch_event_rule" "lambda_function_version_published" {
  count       = var.kosli_environment_type == "lambda" ? 1 : 0
  name        = "${var.name}-lambda-function-version-published"
  description = "Lambda function version has been published"

  event_pattern = jsonencode({
    source      = ["aws.lambda"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      requestParameters = {
        functionName = [var.reported_aws_resource_name]
      }
      responseElements = {
        functionName = [var.reported_aws_resource_name]
      }
    }
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "lambda_function_version_published" {
  count     = var.kosli_environment_type == "lambda" ? 1 : 0
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
    source      = ["aws.s3"]
    resources   = ["arn:aws:s3:::${var.reported_aws_resource_name}"]
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "s3_configuration_updated" {
  count     = var.kosli_environment_type == "s3" ? 1 : 0
  arn       = module.reporter_lambda.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.s3_configuration_updated[0].name
  target_id = "${var.name}-s3-configuration-updated"
}
