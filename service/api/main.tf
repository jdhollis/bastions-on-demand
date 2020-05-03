data "aws_region" "current" {}

resource "aws_api_gateway_rest_api" "bastion" {
  name = "Bastion Management"
}

resource "aws_api_gateway_deployment" "bastion" {
  depends_on = [
    aws_api_gateway_integration.delete_bastion,
    aws_api_gateway_integration.post_bastion,
  ]

  rest_api_id = aws_api_gateway_rest_api.bastion.id
  stage_name  = "demo"
}

resource "aws_api_gateway_method_settings" "bastion" {
  method_path = "*/*"
  rest_api_id = aws_api_gateway_rest_api.bastion.id

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }

  stage_name = aws_api_gateway_deployment.bastion.stage_name
}
