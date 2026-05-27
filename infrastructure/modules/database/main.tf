# =========================================================================
#                 AURORA SERVERLESS V2 DATABASE
# =========================================================================

# 1. DB SUBNET GROUP (Tells RDS which subnets it is allowed to use)
resource "aws_db_subnet_group" "aurora_subnets" {
  name       = "asgard-${var.environment}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "asgard-${var.environment}-db-subnets"
  }
}

# 2. AURORA SERVERLESS V2 CLUSTER (The Storage & Control Plane)
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier = "asgard-${var.environment}-postgres-cluster"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned" # Required for Serverless v2
  engine_version     = "16.1"        # Recommended stable PostgreSQL version

  database_name   = "asgard_cuisines_db"
  master_username = "dbadmin"

  # Best Practice: AWS automatically manages, rotates, and stores the password in Secrets Manager
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.aurora_subnets.name
  vpc_security_group_ids = [var.database_sg_id]

  skip_final_snapshot = true # Set to false in actual production to avoid data loss on destroy

  # Serverless v2 Scaling Logic (Measured in Aurora Capacity Units - ACUs)
  # 0.5 ACU = ~1GB RAM. 
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2.0
  }

  tags = {
    Name = "asgard-${var.environment}-aurora-cluster"
  }
}

# 3. AURORA SERVERLESS V2 INSTANCE (The Compute Nodes)
resource "aws_rds_cluster_instance" "aurora_instance" {
  identifier         = "asgard-${var.environment}-postgres-instance-1"
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  engine             = aws_rds_cluster.aurora_cluster.engine
  engine_version     = aws_rds_cluster.aurora_cluster.engine_version

  # CRITICAL: This exact instance class tells AWS to use the Serverless v2 scaling config
  instance_class = "db.serverless"

  db_subnet_group_name = aws_db_subnet_group.aurora_subnets.name

  tags = {
    Name = "asgard-${var.environment}-aurora-instance-1"
  }
}