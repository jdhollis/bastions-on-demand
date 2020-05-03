output "function_arn" {
  value = aws_lambda_function.destroy_bastion.arn
}

output "function_name" {
  value = aws_lambda_function.destroy_bastion.function_name
}
