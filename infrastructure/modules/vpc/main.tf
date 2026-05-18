# Core Engine/Orchestrator for the VPC module, responsible for creating the VPC and its associated resources

# 1. Custom VPC in eu-west-1 region
resource "aws_vpc" "asgard_vpc" {
  cidr_block           = var.vpc_cidr

  # DNS Configuration
  enable_dns_hostnames = true # Enables the Amazon DNS server (169.254.169.253)
  enable_dns_support   = true # Allows instances to receive public/private DNS names

  # The default_tags from the root provider merge with this local block to ensure all resources get consistent tagging, while allowing for module-specific tags as needed
  tags = {
    Name = "asgard-${var.environment}-vpc"
  }
}

# 2. Internet Gateway for public subnet internet access
resource "aws_internet_gateway" "asgard_igw" {
  vpc_id = aws_vpc.asgard_vpc.id

  tags = {
    Name = "asgard-${var.environment}-igw"
  }
}

# 3. Public Subnets
resource "aws_subnet" "public_sn" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.asgard_vpc.id
  cidr_block        = each.value
  availability_zone = each.key
  
  # Ensures resources dropped here get public IPs if needed down the road
  map_public_ip_on_launch = true 

  tags = {
    Name        = "asgard-${var.environment}-public-sn-${each.key}"
    Type        = "Public"
  }
}

# 4. Private Subnets (Where Lambdas, Aurora, & Endpoints will live)
resource "aws_subnet" "private_sn" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.asgard_vpc.id
  cidr_block        = each.value
  availability_zone = each.key
  
  map_public_ip_on_launch = false

  tags = {
    Name        = "asgard-${var.environment}-private-sn-${each.key}"
    Type        = "Private"
  }
}

# 5. Public Route Table & Internet Route
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.asgard_vpc.id

  route {
    cidr_block = "0.0.0.0/0"  # Default Route to route all IPv4 traffic
    gateway_id = aws_internet_gateway.asgard_igw.id # Target the created Internet Gateway
  }

  tags = {
    Name = "asgard-${var.environment}-public-rt"
  }
}

# 6. Private Route Table (Completely isolated; no NAT Gateway route)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.asgard_vpc.id

  tags = {
    Name = "asgard-${var.environment}-private-rt"
  }
}

# 7. Route Table Associations
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public_sn

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private_sn

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
}