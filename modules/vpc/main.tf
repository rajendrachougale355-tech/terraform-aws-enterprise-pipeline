# 1. Create the VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

# 2. Create an Internet Gateway for Public Routing
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

# 3. Create a Public Subnet (Web Layer)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_blocks[0]
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    Name        = "${var.environment}-public-subnet"
    Environment = var.environment
  }
}

# 4. Create a Private Subnet (App/Database Layer)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_blocks[0]
  availability_zone = "ap-south-1b"

  tags = {
    Name        = "${var.environment}-private-subnet"
    Environment = var.environment
  }
}