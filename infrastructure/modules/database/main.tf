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
  engine_version     = "16.4"        # Recommended stable PostgreSQL version

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

  iam_database_authentication_enabled = true # Allows Lambda to authenticate using IAM roles instead of static passwords

  enabled_cloudwatch_logs_exports = ["postgresql"] # Enables RDS to push database logs to CloudWatch for monitoring and troubleshooting

  copy_tags_to_snapshot = true # Ensures that if you take a snapshot of the cluster, it retains the same tags for easier identification and cost allocation

  storage_encrypted = true # Encrypts the underlying storage volumes for the cluster using AWS-managed keys by default (no custom KMS key needed for dev)

  # checkov:skip=CKV_AWS_327:KMS encryption is bypassed in dev to eliminate custom key costs; default cloud security is sufficient
  # checkov:skip=CKV_AWS_139: No deletion protection to allow easy teardown during development; production environments should set this to true
  # checkov:skip=CKV2_AWS_27:Full PostgreSQL statement query logging is disabled in the development tier to reduce unnecessary CloudWatch log volume overhead and storage baseline costs.
  # checkov:skip=CKV2_AWS_8:Centralized AWS Backup service assignment is bypassed because the cluster uses standard native Aurora automated snapshots and PITR, which are sufficient for dev/sandbox recovery without duplicate cost tiers.
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

  # checkov:skip=CKV_AWS_226:Auto minor upgrades are disabled to maintain strict engine version parity across stages and prevent uncoordinated database restarts outside of managed maintenance windows.
  auto_minor_version_upgrade = false # Intentionally disabled for deterministic change control

  # checkov:skip=CKV_AWS_354:KMS encryption is bypassed in dev to eliminate custom key costs; default cloud security is sufficient
  performance_insights_enabled = true # Enables Performance Insights for advanced database performance monitoring and troubleshooting

  # checkov:skip=CKV_AWS_118:Enhanced monitoring is disabled in dev to eliminate CloudWatch log ingestion charges and avoid unnecessary IAM monitoring role provisioning; standard baseline CloudWatch metrics are sufficient.

  tags = {
    Name = "asgard-${var.environment}-aurora-instance-1"
  }
}