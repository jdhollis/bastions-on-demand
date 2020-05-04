terraform {
  required_version = "~> 0.12.0"
}

provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

module "bastion" {
  source = "./bastion"
  region = var.region
}

module "vpc" {
  source = "./vpc"
  region = var.region
}

data "aws_iam_policy_document" "bastion_task_role" {
  statement {
    actions   = ["sts:AssumeRole"]
    resources = [module.bastion.public_key_fetcher_role_arn]
  }

  #
  # Add any other permissions needed here
  #
}

module "bastion_service" {
  source = "./service"

  image_repository_arn          = module.bastion.repository_arn
  image_repository_url          = module.bastion.repository_url
  public_key_fetcher_role_arn   = module.bastion.public_key_fetcher_role_arn
  public_subnet_ids             = module.vpc.public_subnet_ids
  region                        = var.region
  task_role_policy_json         = data.aws_iam_policy_document.bastion_task_role.json
  vpc_default_security_group_id = module.vpc.default_security_group_id
  vpc_id                        = module.vpc.vpc_id
}
