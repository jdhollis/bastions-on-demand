resource "aws_api_gateway_resource" "bastion" {
  parent_id   = aws_api_gateway_rest_api.bastion.root_resource_id
  path_part   = "bastion"
  rest_api_id = aws_api_gateway_rest_api.bastion.id
}

resource "aws_api_gateway_model" "bastion" {
  rest_api_id  = aws_api_gateway_rest_api.bastion.id
  name         = "Bastion"
  content_type = "application/json"

  schema = <<-EOT
  {
    "$schema": "http://json-schema.org/draft-04/schema#",
    "title": "Bastion",
    "type": "object",
    "additionalProperties": false,
    "properties": {
      "ip": {
        "type": "string"
      }
    },
    "required": [
      "ip"
    ]
  }
  EOT
}

#
# POST /bastion
#

resource "aws_api_gateway_method" "post_bastion" {
  authorization = "AWS_IAM"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.bastion.id
  rest_api_id   = aws_api_gateway_rest_api.bastion.id
}

resource "aws_api_gateway_method_response" "post_bastion" {
  depends_on = [
  aws_api_gateway_method.post_bastion]
  http_method = "POST"
  resource_id = aws_api_gateway_resource.bastion.id

  response_models = {
    "application/json" = aws_api_gateway_model.bastion.name
  }

  rest_api_id = aws_api_gateway_rest_api.bastion.id
  status_code = "201"
}

module "create_bastion_function" {
  source = "./lambda/create-bastion"

  cluster_arn                           = var.cluster_arn
  cluster_name                          = var.cluster_name
  cluster_subnet_ids                    = var.cluster_subnet_ids
  cluster_vpc_default_security_group_id = var.cluster_vpc_default_security_group_id
  cluster_vpc_id                        = var.cluster_vpc_id
  container_name                        = var.container_name
  execution_role_arn                    = var.execution_role_arn
  http_method                           = aws_api_gateway_method.post_bastion.http_method
  resource_path                         = aws_api_gateway_resource.bastion.path
  rest_api_id                           = aws_api_gateway_rest_api.bastion.id
  task_family                           = var.task_family
  task_role_arn                         = var.task_role_arn
}

resource "aws_api_gateway_integration" "post_bastion" {
  http_method             = aws_api_gateway_method.post_bastion.http_method
  resource_id             = aws_api_gateway_resource.bastion.id
  rest_api_id             = aws_api_gateway_rest_api.bastion.id
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.create_bastion_function.function_arn}/invocations"
}

#
# DELETE /bastion
#

resource "aws_api_gateway_method" "delete_bastion" {
  authorization = "AWS_IAM"
  http_method   = "DELETE"
  resource_id   = aws_api_gateway_resource.bastion.id
  rest_api_id   = aws_api_gateway_rest_api.bastion.id
}

resource "aws_api_gateway_method_response" "delete_bastion" {
  depends_on = [
  aws_api_gateway_method.delete_bastion]
  http_method = "POST"
  resource_id = aws_api_gateway_resource.bastion.id

  response_models = {
    "application/json" = "Empty"
  }

  rest_api_id = aws_api_gateway_rest_api.bastion.id
  status_code = "200"
}

module "destroy_bastion_function" {
  source = "./lambda/destroy-bastion"

  cluster_arn                           = var.cluster_arn
  cluster_name                          = var.cluster_name
  cluster_vpc_default_security_group_id = var.cluster_vpc_default_security_group_id
  cluster_vpc_id                        = var.cluster_vpc_id
}

module "trigger_bastion_destruction_function" {
  source = "./lambda/trigger-bastion-destruction"

  destroy_bastion_function_arn  = module.destroy_bastion_function.function_arn
  destroy_bastion_function_name = module.destroy_bastion_function.function_name
  http_method                   = aws_api_gateway_method.delete_bastion.http_method
  resource_path                 = aws_api_gateway_resource.bastion.path
  rest_api_id                   = aws_api_gateway_rest_api.bastion.id
}

resource "aws_api_gateway_integration" "delete_bastion" {
  http_method             = aws_api_gateway_method.delete_bastion.http_method
  resource_id             = aws_api_gateway_resource.bastion.id
  rest_api_id             = aws_api_gateway_rest_api.bastion.id
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${module.trigger_bastion_destruction_function.function_arn}/invocations"
}
