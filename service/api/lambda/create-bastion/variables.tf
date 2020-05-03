variable "cluster_arn" {}
variable "cluster_name" {}

variable "cluster_subnet_ids" {
  type = list(string)
}

variable "cluster_vpc_default_security_group_id" {}
variable "cluster_vpc_id" {}
variable "container_name" {}
variable "execution_role_arn" {}
variable "http_method" {}
variable "resource_path" {}
variable "rest_api_id" {}
variable "task_family" {}
variable "task_role_arn" {}
