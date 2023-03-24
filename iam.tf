data "aws_iam_policy_document" "ecs_read_allow" {
  count = var.kosli_environment_type == "ecs" && !var.use_custom_policy ? 1 : 0
  statement {
    sid    = "ECSList"
    effect = "Allow"
    actions = [
      "ecs:ListClusters",
      "ecs:ListServices",
      "ecs:ListTasks"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "ECSDescribe"
    actions = [
      "ecs:DescribeServices",
      "ecs:DescribeTasks",
      "ecs:DescribeClusters",
    ]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/*",
    ]
  }
}

data "aws_iam_policy_document" "lambda_read_allow" {
  count = var.kosli_environment_type == "lambda" && !var.use_custom_policy ? 1 : 0
  statement {
    sid    = "LambdaRead"
    effect = "Allow"
    actions = [
      "lambda:GetFunctionConfiguration"
    ]
    resources = [
      "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"
    ]
  }
}

data "aws_iam_policy_document" "combined" {
  count = !var.use_custom_policy ? 1 : 0
  source_policy_documents = concat(
    data.aws_iam_policy_document.ecs_read_allow.*.json,
    data.aws_iam_policy_document.lambda_read_allow.*.json
  )
}
