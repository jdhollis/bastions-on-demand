output "function_arn" {
  value = aws_lambda_function.create_bastion.arn
}

output "function_name" {
  value = aws_lambda_function.create_bastion.function_name
}
