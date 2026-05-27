# =========================================================================
#       SERVERLESS LAMBDA DEPLOYMENT ARTIFACT BUCKET 
# =========================================================================

# 1. RANDOM SUFFIX GENERATOR (Guarantees global S3 naming uniqueness)
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# 2. THE S3 BUCKET CONTAINER
resource "aws_s3_bucket" "lambda_artifacts" {
  bucket        = "asgard-${var.environment}-lambda-artifacts-${random_id.bucket_suffix.hex}"
  force_destroy = var.environment == "production" ? false : true # Prevent accidental prod wiping

  tags = {
    Name = "asgard-${var.environment}-lambda-artifacts"
  }
}

# 3. PUBLIC ACCESS BLOCKER (Enforces absolute Zero-Trust perimeter isolation)
resource "aws_s3_bucket_public_access_block" "lambda_artifacts_privacy" {
  bucket = aws_s3_bucket.lambda_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. VERSIONING ENGINE (Allows clean point-in-time CI/CD rollbacks if an app deployment fails)
resource "aws_s3_bucket_versioning" "lambda_artifacts_versioning" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 5. FINOPS LIFECYCLE CONFIGURATION (Automated Storage Cost Mitigation)
resource "aws_s3_bucket_lifecycle_configuration" "lambda_artifacts_lifecycle" {
  bucket = aws_s3_bucket.lambda_artifacts.id

  rule {
    id     = "cleanup_historical_deployments_and_ghost_costs"
    status = "Enabled"

    # Optimization 1: Clean up incomplete multipart uploads after 7 days.
    # Prevents "ghost storage" fees if a CI/CD network blip breaks an upload halfway through.
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Optimization 2: Zero-Trust Rollback Retention Policy
    # Keep the active version forever, but clean up older deployment history.
    noncurrent_version_expiration {
      noncurrent_days           = 30 # Delete old versions once they've been inactive for 30 days
      newer_noncurrent_versions = 3  # CRITICAL: Always keep the last 3 historical versions for emergency rollbacks!
    }
  }
}


# -----------------------------------------------------------------------------------------
# INFRASTRUCTURE BOOTSTRAP LOGIC (Prevents Lambda function first-run compilation failures)
# -----------------------------------------------------------------------------------------

# Generate a temporary, functional zip package locally during compile time
data "archive_file" "bootstrap_package" {
  type        = "zip"
  output_path = "${path.module}/files/bootstrap.zip"

  source {
    content  = "def handler(event, context):\n    return {'statusCode': 200, 'body': 'Asgard Lambda Engine Initialized'}"
    filename = "index.py"
  }
}

# Upload the inline code block as the initial blueprint target
resource "aws_s3_object" "lambda_bootstrap_artifact" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  key    = "django-api/v1-bootstrap.zip"
  source = data.archive_file.bootstrap_package.output_path
  etag   = filemd5(data.archive_file.bootstrap_package.output_path)

  lifecycle {
    ignore_changes = [source, etag] # Ensures CI/CD overrides don't get wiped by future terraform runs!
  }
}


# =========================================================================
#       STATIC ASSETS BUCKET (FRONTEND & DJANGO STATIC FILES)
# =========================================================================

# 1. THE S3 BUCKET CONTAINER
resource "aws_s3_bucket" "static_assets" {
  bucket        = "asgard-${var.environment}-static-assets-${random_id.bucket_suffix.hex}"
  force_destroy = var.environment == "production" ? false : true

  tags = {
    Name = "asgard-${var.environment}-static-assets"
  }
}

# 2. PUBLIC ACCESS BLOCKER (Enforces absolute Zero-Trust perimeter isolation)
# Note: CloudFront uses Origin Access Control (OAC) to securely bypass this block.
resource "aws_s3_bucket_public_access_block" "static_assets_privacy" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}