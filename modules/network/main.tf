# Provider
provider "aws" {
  region = "us-east-1"
}

# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}


# New VPC
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = merge(
    var.default_tags, {
      Name = "${var.prefix}-${var.env}-vpc"
    }
  )
}


# Add provisioning of the public subnet in the default VPC
resource "aws_subnet" "public_subnet" {
  count             = length(var.public_cidr_blocks)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_cidr_blocks[count.index]
  availability_zone = var.zones[count.index]
  tags = merge(
    var.default_tags, {
      Name = "${var.prefix}-${var.env}-public-subnet-${count.index + 1}"
    }
  )
}

# Add provisioning of the private subnets in the custom VPC
resource "aws_subnet" "private_subnet" {
  count             = length(var.private_cidr_blocks)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidr_blocks[count.index]
  availability_zone = var.zones[count.index]
  tags = merge(
    var.default_tags, {
      Name = "${var.prefix}-${var.env}-private-subnet-${count.index + 1}"
      Tier = "Private"
    }
  )
}

# Creating an Internet Gateway
resource "aws_internet_gateway" "internetGateWay" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.default_tags,
    {
      "Name" = "${var.prefix}-${var.env}-internetGateWay"
    }
  )
}

# Route table to add default gateway pointing to Internet Gateway (IGW)
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internetGateWay.id
  }
  tags = {
    Name = "${var.prefix}-${var.env}-route-public-route_table"
  }
}

# Associating the public subnet with route table
resource "aws_route_table_association" "public_route_table_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet[0].id
}

#Creating NAT GW
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "${var.prefix}-natgw"
  }

  # adding dependecy on IGW explicitly for proper ordering
  depends_on = [aws_internet_gateway.internetGateWay]
}

# Create elastic IP for NAT GW
resource "aws_eip" "nat-eip" {
  vpc = true
  tags = {
    Name = "${var.prefix}-${var.env}-natgw"
  }

}

# Route table to route add default gateway pointing to NAT Gateway (NATGW)
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.prefix}-${var.env}-route-private-route_table",
    Tier = "Private"
  }
}

# Add route to NAT GW if we created public subnets
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat-gw.id
}

# Associate subnets with the custom route table
resource "aws_route_table_association" "private_route_table_association" {
  count          = length(aws_subnet.private_subnet[*].id)
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}