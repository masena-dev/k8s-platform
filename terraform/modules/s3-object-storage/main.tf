terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

locals {
  # S3-compatible buckets are globally unique, so callers should pass a stable
  # prefix derived from something they already own (typically a domain plus a
  # cluster name). Sanitize and trim here so every caller gets valid names.
  raw_bucket_prefix = var.bucket_prefix

  sanitized_bucket_prefix = trim(
    replace(
      replace(lower(local.raw_bucket_prefix), "/[^a-z0-9-]/", "-"),
      "/-+/",
      "-"
    ),
    "-"
  )

  max_suffix_length = max([for name in var.bucket_names : length(name)]...)
  max_prefix_length = 63 - local.max_suffix_length - 1
  bucket_prefix     = trim(substr(local.sanitized_bucket_prefix, 0, local.max_prefix_length), "-")
}

resource "aws_s3_bucket" "buckets" {
  for_each      = toset(var.bucket_names)
  bucket        = "${local.bucket_prefix}-${each.value}"
  force_destroy = var.force_destroy
}
