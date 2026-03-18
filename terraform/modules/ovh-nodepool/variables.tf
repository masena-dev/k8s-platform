variable "project_id" {
  description = "OVH Public Cloud project ID"
  type        = string
}

variable "cluster_id" {
  description = "ID of the Kubernetes cluster"
  type        = string
}

variable "pool_name" {
  description = "Base name for the node pool"
  type        = string
  default     = "default"
}

variable "flavor" {
  description = "OVH instance flavor for the nodes"
  type        = string
  default     = "b3-8"
}

variable "desired_nodes" {
  description = "Desired number of nodes in the pool"
  type        = number
  default     = 3
}

variable "min_nodes" {
  description = "Minimum number of nodes in the pool"
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Maximum number of nodes in the pool"
  type        = number
  default     = 5
}

variable "autoscale" {
  description = "Enable autoscaling for the node pool"
  type        = bool
  default     = true
}
