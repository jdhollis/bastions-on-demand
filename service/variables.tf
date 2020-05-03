variable "image_repository_arn" {}
variable "image_repository_url" {}
variable "public_key_fetcher_role_arn" {}

variable "public_subnet_ids" {
  type = list(string)
}

variable "region" {}
variable "task_role_policy_json" {}
variable "vpc_default_security_group_id" {}
variable "vpc_id" {}
