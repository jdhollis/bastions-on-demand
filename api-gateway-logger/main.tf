terraform {
  required_version = "~> 0.12.0"
}

provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["apigateway.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "logger" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:FilterLogEvents",
      "logs:GetLogEvents",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "logger" {
  name               = "api-gateway-cloudwatch-logger"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "logger" {
  name   = "api-gateway-cloudwatch-logger"
  policy = data.aws_iam_policy_document.logger.json
  role   = aws_iam_role.logger.name
}

resource "aws_api_gateway_account" "global" {
  cloudwatch_role_arn = aws_iam_role.logger.arn
}
