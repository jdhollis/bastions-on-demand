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

#
# NAT Gateway

#
# AZ A
#

resource "aws_eip" "nat_az_a" {
  depends_on = [aws_internet_gateway.demo]
  vpc        = true

  tags = {
    Name = "bastions-on-demand-demo-nat-az-a"
  }
}

resource "aws_nat_gateway" "az_a" {
  allocation_id = aws_eip.nat_az_a.id
  subnet_id     = aws_subnet.public_az_a.id

  tags = {
    Name = "bastions-on-demand-demo-nat-az-a"
  }
}

#
# Routing

#
# Public
#

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "bastions-on-demand-demo-public"
  }
}

resource "aws_route" "igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.demo.id
}

resource "aws_route_table_association" "public_az_a" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_az_a.id
}
