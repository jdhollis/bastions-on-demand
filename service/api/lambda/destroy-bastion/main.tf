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

resource "aws_sqs_queue" "dlq" {
  name = "destroy-bastion-dlq"
}

data "aws_iam_policy_document" "destroy_bastion" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/destroy-bastion",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/destroy-bastion:*",
    ]
  }

  statement {
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.dlq.arn]
  }

  statement {
    actions = [
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:RevokeSecurityGroupIngress",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecs:DescribeTask*",
      "ecs:ListTask*",
      "ecs:StopTask",
    ]

    resources = ["*"]

    condition {
      test     = "ArnEquals"
      values   = [var.cluster_arn]
      variable = "ecs:cluster"
    }
  }
}

resource "aws_iam_role" "destroy_bastion" {
  name               = "destroy-bastion"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "destroy_bastion" {
  name   = "destroy-bastion"
  policy = data.aws_iam_policy_document.destroy_bastion.json
  role   = aws_iam_role.destroy_bastion.name
}

resource "aws_lambda_function" "destroy_bastion" {
  filename         = "${path.module}/target/destroy-bastion.jar"
  function_name    = "destroy-bastion"
  handler          = "bastion.destroy"
  memory_size      = 512
  publish          = true
  role             = aws_iam_role.destroy_bastion.arn
  runtime          = "java8"
  source_code_hash = filebase64sha256("${path.module}/target/destroy-bastion.jar")
  timeout          = 120

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  environment {
    variables = {
      CLUSTER_NAME                          = var.cluster_name
      CLUSTER_VPC_DEFAULT_SECURITY_GROUP_ID = var.cluster_vpc_default_security_group_id
      CLUSTER_VPC_ID                        = var.cluster_vpc_id
    }
  }
}
