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

data "aws_iam_policy_document" "create_bastion" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/create-bastion$",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/create-bastion:*",
    ]
  }

  statement {
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecs:DescribeTask*",
      "ecs:ListTask*",
      "ecs:RunTask",
      "ecs:StopTask",
    ]

    resources = ["*"]

    condition {
      test     = "ArnEquals"
      values   = [var.cluster_arn]
      variable = "ecs:cluster"
    }
  }

  statement {
    actions = ["iam:PassRole"]

    resources = [
      var.execution_role_arn,
      var.task_role_arn,
    ]

    condition {
      test     = "StringLike"
      values   = ["ecs-tasks.amazonaws.com"]
      variable = "iam:PassedToService"
    }
  }
}

resource "aws_iam_role" "create_bastion" {
  name               = "create-bastion"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "create_bastion" {
  name   = "create-bastion"
  policy = data.aws_iam_policy_document.create_bastion.json
  role   = aws_iam_role.create_bastion.name
}

resource "aws_lambda_function" "create_bastion" {
  filename         = "${path.module}/target/create-bastion.jar"
  function_name    = "create-bastion"
  handler          = "bastion.create"
  memory_size      = 512
  publish          = true
  role             = aws_iam_role.create_bastion.arn
  runtime          = "java8"
  source_code_hash = filebase64sha256("${path.module}/target/create-bastion.jar")
  timeout          = 120

  environment {
    variables = {
      CLUSTER_NAME                          = var.cluster_name
      CLUSTER_SUBNET_IDS                    = join(",", var.cluster_subnet_ids)
      CLUSTER_VPC_DEFAULT_SECURITY_GROUP_ID = var.cluster_vpc_default_security_group_id
      CLUSTER_VPC_ID                        = var.cluster_vpc_id
      CONTAINER_NAME                        = var.container_name
      TASK_FAMILY                           = var.task_family
    }
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_bastion.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.rest_api_id}/*/${var.http_method}${var.resource_path}"
}
