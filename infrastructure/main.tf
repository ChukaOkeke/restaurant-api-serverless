# ===========================================================
# ROOT MODULE FOR ENVIRONMENT ORCHESTRATION: ASGARD CUISINES
# ===========================================================

# Create the VPC and its associated resources (subnets, route tables, security groups, interface endpoints etc.)
module "vpc" {
  source = "./modules/vpc"

  # Overriding or explicitly declaring the configuration values, though it will default to what we wrote in the module variables if omitted
  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  db_port         = var.db_port
}

# Create the Aurora Serverless v2 Cluster and its associated resources (DB Subnet Group, Cluster Instance etc.)
module "database" {
  source = "./modules/database"

  environment        = var.environment
  
  # Passing the outputs from the VPC module straight into the Database module.
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  database_sg_id     = module.vpc.database_sg_id
}

# Create the SQS Queues for asynchronous decoupling of the booking process
module "messaging" {
  source = "./modules/messaging"

  environment                = var.environment
  queue_delay_seconds        = var.queue_delay_seconds
  max_message_size           = var.max_message_size
  queue_retention_seconds    = var.queue_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  dlq_retention_seconds      = var.dlq_retention_seconds
  max_receive_count          = var.max_receive_count
}

# Create the IAM Role for GitHub Actions OIDC authentication and the Secrets Manager container for application secrets
module "security" {
  source = "./modules/security"

  environment = var.environment
  github_org  = var.github_org
  github_repo = var.github_repo
}

# Create the S3 bucket for Lambda deployment artifacts
module "storage" {
  source      = "./modules/storage"
  environment = var.environment
}

# Create Lambda Serverless Infrastructure for both the Web API and the Asynchronous Queue Worker
module "compute" {
  source = "./modules/compute"

  environment        = var.environment
  private_subnet_ids = module.vpc.private_subnet_ids
  lambda_sg_id       = module.vpc.lambda_sg_id

  # Storage references
  s3_bucket_id     = module.storage.bucket_name
  s3_bootstrap_key = module.storage.bootstrap_object_key

  # Messaging queues references
  sqs_queue_arn = module.messaging.queue_arn
  sqs_queue_id  = module.messaging.queue_id

  # Security / Secrets handles references
  rds_secret_arn  = module.database.rds_secret_arn
  app_secrets_arn = module.security.app_secrets_arn
}