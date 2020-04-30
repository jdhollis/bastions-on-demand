output "public_key_fetcher_role_arn" {
  value = aws_iam_role.public_key_fetcher.arn
}

output "repository_arn" {
  value = aws_ecr_repository.bastion.arn
}

output "repository_url" {
  value = aws_ecr_repository.bastion.repository_url
}
