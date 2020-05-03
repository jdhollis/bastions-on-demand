output "function_arn" {
  value = aws_lambda_function.trigger_bastion_destruction.arn
}

output "function_name" {
  value = aws_lambda_function.trigger_bastion_destruction.function_name
}
