data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "trigger_bastion_destruction" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/trigger-bastion-destruction",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/trigger-bastion-destruction:*",
    ]
  }

  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [var.destroy_bastion_function_arn]
  }
}

resource "aws_iam_role" "trigger_bastion_destruction" {
  name               = "trigger-bastion-destruction"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "trigger_bastion_destruction" {
  name   = "trigger-bastion-destruction"
  policy = data.aws_iam_policy_document.trigger_bastion_destruction.json
  role   = aws_iam_role.trigger_bastion_destruction.name
}

resource "aws_lambda_function" "trigger_bastion_destruction" {
  filename         = "${path.module}/target/trigger-bastion-destruction.zip"
  function_name    = "trigger-bastion-destruction"
  handler          = "handler.handle_request"
  memory_size      = 512
  publish          = true
  role             = aws_iam_role.trigger_bastion_destruction.arn
  runtime          = "nodejs12.x"
  source_code_hash = filebase64sha256("${path.module}/target/trigger-bastion-destruction.zip")

  environment {
    variables = {
      DESTROY_BASTION_FUNCTION_NAME = var.destroy_bastion_function_name
    }
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_bastion_destruction.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.rest_api_id}/*/${var.http_method}${var.resource_path}"
}
