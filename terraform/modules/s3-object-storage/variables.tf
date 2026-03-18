variable "bucket_prefix" {
  description = "Prefix for all bucket names (typically the cluster name)."
  type        = string
}

variable "bucket_names" {
  description = "Logical bucket names to create. Each gets prefixed with bucket_prefix."
  type        = list(string)
  default     = ["loki-chunks", "loki-ruler"]
}

variable "force_destroy" {
  description = "Delete bucket contents when destroying starter-kit managed object storage. This keeps teardown reproducible after Loki or CNPG have written data."
  type        = bool
  default     = true
}
