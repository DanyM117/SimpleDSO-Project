data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.project_prefix}-tfstate-${data.aws_caller_identity.current.account_id}"
  dynamodb_table = "${var.project_prefix}-tfstate-lock"
}

# Bucket S3
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_name
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
}

# Versionamiento
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# SSE-S3 Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto" {
    bucket = aws_s3_bucket.terraform_state.id
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = true
    }
}

# Public access block
resource "aws_s3_bucket_public_access_block" "terraform_state_access" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls = true
  ignore_public_acls = true
  restrict_public_buckets = true
  block_public_policy = true
}

# DynamoDB table
resource "aws_dynamodb_table" "terraform_locks" {
  name = local.dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}