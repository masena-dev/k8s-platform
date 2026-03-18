variable "network_name" {
  description = "Name of the private network"
  type        = string
}

variable "region" {
  description = "OVH region for the network"
  type        = string
  default     = "DE1"
}

variable "subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "192.168.100.0/24"
}
