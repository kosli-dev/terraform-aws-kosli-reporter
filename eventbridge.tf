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
  count = var.kosli_environment_type == "ecs" ? 1 : 0
  name        = "${var.name}-lambda-task-updated"
  description = "Capture ECS task update"

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Task State Change"]
    detail      = {
      clusterArn = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.ecs_cluster_name}"]
      desiredStatus = ["RUNNING"]
      lastStatus = ["RUNNING"]
    }
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "ecs_task_updated" {
  count = var.kosli_environment_type == "ecs" ? 1 : 0
  arn       = module.reporter_lambda.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.ecs_task_updated[0].name
  target_id = "${module.reporter_lambda.lambda_function_name}-ecs-task-updated"
}
