# =========================================================================
#  SECURITY GROUPS FOR THE ARCHITECTURE
# =========================================================================

# -------------------------------------------------------------------------
# 1. SECURITY GROUP CONTAINERS (Without rules to avoid cyclical dependencies)
# -------------------------------------------------------------------------

# LAMBDA SECURITY GROUP
resource "aws_security_group" "lambda" {
  name        = "asgard-${var.environment}-lambda-sg"
  description = "Security group for private backend Lambda functions"
  vpc_id      = aws_vpc.asgard_vpc.id

  tags = {
    Name = "asgard-${var.environment}-lambda-sg"
  }
}

# VPC INTERFACE ENDPOINTS SECURITY GROUP
resource "aws_security_group" "vpc_endpoints" {
  name        = "asgard-${var.environment}-endpoints-sg"
  description = "Security group for shared VPC Interface Endpoints"
  vpc_id      = aws_vpc.asgard_vpc.id

  tags = {
    Name = "asgard-${var.environment}-endpoints-sg"
  }
}

# DATABASE SECURITY GROUP
resource "aws_security_group" "database" {
  name        = "asgard-${var.environment}-database-sg"
  description = "Security group for Aurora Serverless v2 Cluster"
  vpc_id      = aws_vpc.asgard_vpc.id

  tags = {
    Name = "asgard-${var.environment}-database-sg"
  }
}

# BASTION HOST SECURITY GROUP
resource "aws_security_group" "bastion" {
  name        = "asgard-${var.environment}-bastion-sg"
  description = "Security group for administrative bastion host"
  vpc_id      = aws_vpc.asgard_vpc.id

  # Locked down by default, ready for your specific IP or SSM sessions
  egress {
    description = "Allow all outbound traffic from bastion for management tasks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # checkov:skip=CKV_AWS_382:Full egress is intentionally allowed from the bastion host to enable necessary management operations, including patching, updates, and secure outbound connections for administrative tasks. Access to the bastion is tightly controlled via ingress rules and IAM policies, ensuring that only authorized personnel can utilize this access point.
  tags = {
    Name = "asgard-${var.environment}-bastion-sg"
  }
}


# -------------------------------------------------------------------------
# 2. DECOUPLED STANDALONE RULES
# -------------------------------------------------------------------------

# LINK 1: LAMBDA <=> VPC INTERFACE ENDPOINTS

resource "aws_vpc_security_group_egress_rule" "lambda_to_endpoints" {
  security_group_id            = aws_security_group.lambda.id
  description                  = "Allow outbound HTTPS from Lambda to reach VPC Interface Endpoints"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_lambda" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  description                  = "Allow HTTPS from Lambda compute"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.lambda.id
}

# LINK 2: LAMBDA <=> AURORA POSTGRESQL DATABASE

resource "aws_vpc_security_group_egress_rule" "lambda_to_database" {
  security_group_id            = aws_security_group.lambda.id
  description                  = "Allow outbound PostgreSQL traffic strictly to the database cluster"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.database.id
}

resource "aws_vpc_security_group_ingress_rule" "database_from_lambda" {
  security_group_id            = aws_security_group.database.id
  description                  = "Allow PostgreSQL from Lambda compute"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.lambda.id
}