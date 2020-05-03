output "public_subnet_ids" {
  value = [aws_subnet.public_az_a.id]
}

output "default_security_group_id" {
  value = aws_vpc.demo.default_security_group_id
}

output "vpc_id" {
  value = aws_vpc.demo.id
}
