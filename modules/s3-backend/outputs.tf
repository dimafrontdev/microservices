output "s3_bucket" {
  description = "The name of the created S3 bucket"
  value       = aws_s3_bucket.tf_state.id
}

output "dynamodb_table" {
  description = "The name of the DynamoDB table used for state locking"
  value       = aws_dynamodb_table.tf_locks.name
}
