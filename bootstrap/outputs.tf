output "s3_bucket_name" {
  description = "Name of the backend S3 bucket"
  value = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "State lock dynamodb table name"
  value = aws_dynamodb_table.terraform_locks.name
}

output "aws_region" {
  description = "Backend s3 region"
  value = var.aws_region
}

output "aws_sns_topic_bucket" {
  description = "Name of the sns topic created"
  value = aws_sns_topic.bucket_notifications.name
}