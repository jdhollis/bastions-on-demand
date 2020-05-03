resource "aws_vpc" "demo" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "bastions-on-demand-demo"
  }
}

resource "aws_internet_gateway" "demo" {
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "bastions-on-demand-demo"
  }
}

#
# Subnets
#

#
# Address space layout:
#
# 10.0.0.0/16:
#   10.0.0.0/18 — AZ A
#     10.0.0.0/19 — Spare
#     10.0.32.0/19
#       10.0.32.0/20 — Public
#       10.0.48.0/20 – Spare
#   10.0.64.0/18 — Spare
#

#
# AZ A
#

resource "aws_subnet" "public_az_a" {
  cidr_block        = cidrsubnet("10.0.0.0/16", 4, 2)
  vpc_id            = aws_vpc.demo.id
  availability_zone = "${var.region}a"

  tags = {
    Name = "bastions-on-demand-demo-public-az-a"
  }
}
