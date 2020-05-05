output "bastion_service_endpoint" {
  value = module.bastion_service.endpoint
}

output "region" {
  value = var.region
}
