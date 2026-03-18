output "access_key" {
  description = "S3 access key ID"
  value       = ovh_cloud_project_user_s3_credential.storage.access_key_id
  sensitive   = true
}

output "secret_key" {
  description = "S3 secret access key"
  value       = ovh_cloud_project_user_s3_credential.storage.secret_access_key
  sensitive   = true
}

output "endpoint" {
  description = "S3 endpoint URL (e.g., s3.gra.io.cloud.ovh.net)"
  value       = "s3.${lower(var.region)}.io.cloud.ovh.net"
}

output "region" {
  description = "S3 region (lowercase, for Loki config)"
  value       = lower(var.region)
}

output "bucket_names" {
  description = "Map of logical name to actual bucket name"
  value       = { for name in var.bucket_names : name => "${local.bucket_prefix}-${name}" }
}
