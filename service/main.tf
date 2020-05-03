provider "template" {
  version = "~> 2.1"
}

resource "aws_cloudwatch_log_group" "bastion" {
  name = "bastion"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "execution_role" {
  name               = "bastion-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "execution_role" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    resources = [var.image_repository_arn]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "execution_role" {
  name   = "bastion-execution"
  policy = data.aws_iam_policy_document.execution_role.json
  role   = aws_iam_role.execution_role.id
}

resource "aws_iam_role" "task_role" {
  name               = "bastion-task"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "task_role" {
  policy = var.task_role_policy_json
  role   = aws_iam_role.task_role.id
}

resource "aws_ecs_cluster" "bastion" {
  name = "bastions"
}

data "template_file" "container_definitions" {
  template = file("${path.module}/container-definitions.tpl.json")

  vars = {
    assume_role_for_authorized_keys = var.public_key_fetcher_role_arn
    image                           = "${var.image_repository_url}:latest"
    log_group_name                  = aws_cloudwatch_log_group.bastion.name
    name                            = "bastion"
    region                          = var.region
  }
}

resource "aws_ecs_task_definition" "bastion" {
  container_definitions    = data.template_file.container_definitions.rendered
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.execution_role.arn
  family                   = "bastions"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task_role.arn
}

module "api" {
  source = "./api"

  cluster_arn                           = aws_ecs_cluster.bastion.arn
  cluster_name                          = aws_ecs_cluster.bastion.name
  cluster_subnet_ids                    = var.public_subnet_ids
  cluster_vpc_default_security_group_id = var.vpc_default_security_group_id
  cluster_vpc_id                        = var.vpc_id
  container_name                        = "bastion"
  execution_role_arn                    = aws_iam_role.execution_role.arn
  task_family                           = aws_ecs_task_definition.bastion.family
  task_role_arn                         = aws_iam_role.task_role.arn
}
