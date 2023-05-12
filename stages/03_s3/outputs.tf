output "s3_bucket_id" {
  description = "The name of the TF bucket."
  value       = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "The ARN of the TF bucket. Will be of format arn:aws:s3:::bucketname."
  value       = module.s3_bucket.s3_bucket_arn
}

output "s3_bucket_region" {
  description = "The AWS region TF bucket resides in."
  value       = module.s3_bucket.s3_bucket_region
}