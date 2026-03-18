# Dedicated user for object storage access
resource "ovh_cloud_project_user" "storage" {
  service_name = var.project_id
  description  = "${var.cluster_name}-object-storage"
  role_names   = ["objectstore_operator"]
}

# S3 credentials for the user
resource "ovh_cloud_project_user_s3_credential" "storage" {
  service_name = var.project_id
  user_id      = ovh_cloud_project_user.storage.id
}

# OVH Object Storage uses S3-compatible buckets with a globally-unique namespace
# (similar to AWS S3). To avoid collisions across accounts, allow callers to
# provide a stable, unique prefix (e.g. derived from a domain).
locals {
  raw_bucket_prefix = var.bucket_prefix != "" ? var.bucket_prefix : var.cluster_name

  # Sanitize to S3 bucket naming rules:
  # - lowercase letters, numbers, hyphens
  # - must start/end with letter/number
  sanitized_bucket_prefix = trim(
    replace(
      replace(lower(local.raw_bucket_prefix), "/[^a-z0-9-]/", "-"),
      "/-+/",
      "-"
    ),
    "-"
  )

  max_suffix_length = max([for name in var.bucket_names : length(name)]...)
  # S3 bucket names max 63 chars, and we add a "-" between prefix and suffix.
  max_prefix_length = 63 - local.max_suffix_length - 1
  bucket_prefix     = trim(substr(local.sanitized_bucket_prefix, 0, local.max_prefix_length), "-")
}

# Create each bucket via the OVH provider (managed resource, destroyed on terraform destroy)
resource "ovh_cloud_project_storage" "buckets" {
  for_each = toset(var.bucket_names)

  service_name = var.project_id
  region_name  = var.region
  name         = "${local.bucket_prefix}-${each.value}"
}

# Scope IAM policy to only these buckets
resource "ovh_cloud_project_user_s3_policy" "storage" {
  service_name = var.project_id
  user_id      = ovh_cloud_project_user.storage.id
  policy = jsonencode({
    Statement = [
      {
        Sid    = "ObjectStorage"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
        ]
        Resource = flatten([
          for name in var.bucket_names : [
            "arn:aws:s3:::${local.bucket_prefix}-${name}",
            "arn:aws:s3:::${local.bucket_prefix}-${name}/*",
          ]
        ])
      },
    ]
  })
}
