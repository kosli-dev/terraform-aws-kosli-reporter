resource "aws_cloudwatch_event_rule" "cron_every_minute" {
  name        = "run-${var.name}-lambda-reporter-cron"
  description = "Execute ${var.name} lambda reporter by cron"

  schedule_expression = var.schedule_expression

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "ecs_service_updated" {
  name        = "run-${var.name}-lambda-service-updated"
  description = "Capture each AWS Console Sign In"

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Service Action"]
    detail      = {
      clusterArn = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.ecs_cluster}"]
      eventName  = ["SERVICE_STEADY_STATE"]
    }
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "cron" {
  arn       = module.reporter_lambda.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.cron_every_minute.name
  target_id = "${module.reporter_lambda.lambda_function_name}-cron"
}

resource "aws_cloudwatch_event_target" "ecs_service_updated" {
  arn       = module.reporter_lambda.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.ecs_service_updated.name
  target_id = "${module.reporter_lambda.lambda_function_name}-ecs-service-changed"
}
