variable "project_id" {
  description = "OVH Cloud project ID (service_name)"
  type        = string
}

variable "cluster_name" {
  description = "Cluster name, used for naming resources"
  type        = string
}

variable "bucket_prefix" {
  description = "Prefix for globally-unique bucket names. If empty, defaults to cluster_name. This value is sanitized to S3 bucket naming rules."
  type        = string
  default     = ""
}

variable "region" {
  description = "OVH S3 high-performance storage region. Valid values: GRA, SBG, BHS. This is NOT the cluster region."
  type        = string
  default     = "GRA"
}

variable "bucket_names" {
  description = "List of bucket names to create"
  type        = list(string)
  default     = ["loki-chunks", "loki-ruler", "cnpg-backups"]
}
