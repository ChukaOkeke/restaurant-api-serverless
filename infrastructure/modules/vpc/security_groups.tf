# =========================================================================
#  SECURITY GROUPS FOR THE ARCHITECTURE
# =========================================================================

# 1. LAMBDA COMPUTE SECURITY GROUP
resource "aws_security_group" "lambda" {
  name        = "asgard-${var.environment}-lambda-sg"
  description = "Security group for private backend Lambda functions"
  vpc_id      = aws_vpc.asgard_vpc.id

  # Egress: Lambda needs to initiate outbound connections to the VPC
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Required to reach VPC Endpoints & internal resources
  }

  tags = {
    Name = "asgard-${var.environment}-lambda-sg"
  }
}

# 2. VPC INTERFACE ENDPOINTS SECURITY GROUP (Shared for SQS, Secrets, SES)
resource "aws_security_group" "vpc_endpoints" {
  name        = "asgard-${var.environment}-endpoints-sg"
  description = "Security group for shared VPC Interface Endpoints"
  vpc_id      = aws_vpc.asgard_vpc.id

  # Ingress: Only accept HTTPS traffic if it originates from our Lambda SG
  ingress {
    description     = "Allow HTTPS from Lambda compute"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id] # The Chain Link
  }

  tags = {
    Name = "asgard-${var.environment}-endpoints-sg"
  }
}

# 3. AURORA SERVERLESS V2 DATABASE SECURITY GROUP
resource "aws_security_group" "database" {
  name        = "asgard-${var.environment}-database-sg"
  description = "Security group for Aurora Serverless v2 Cluster"
  vpc_id      = aws_vpc.asgard_vpc.id

  # Ingress: Only accept DB traffic if it originates from our Lambda SG
  ingress {
    description     = "Allow PostgreSQL/MySQL from Lambda compute"
    from_port       = var.db_port # Dynamically typed input variable
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id] # The Chain Link
  }

  tags = {
    Name = "asgard-${var.environment}-database-sg"
  }
}

# 4. MANAGEMENT BASTION SECURITY GROUP (For Secure Admin Access)
resource "aws_security_group" "bastion" {
  name        = "asgard-${var.environment}-bastion-sg"
  description = "Security group for administrative bastion host"
  vpc_id      = aws_vpc.asgard_vpc.id

  # Locked down by default, ready for your specific IP or SSM sessions
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "asgard-${var.environment}-bastion-sg"
  }
}