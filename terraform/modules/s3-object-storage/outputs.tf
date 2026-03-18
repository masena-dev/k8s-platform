output "bucket_names" {
  description = "Map of logical name to actual bucket name."
  value       = { for name in var.bucket_names : name => aws_s3_bucket.buckets[name].bucket }
}
