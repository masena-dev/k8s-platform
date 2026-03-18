variable "project_id" {
  description = "OVH Public Cloud project ID"
  type        = string
}

variable "network_id" {
  description = "ID of the private network"
  type        = string
}

variable "subnet_id" {
  description = "ID of the private subnet"
  type        = string
}

variable "region" {
  description = "OVH region for the database"
  type        = string
  default     = "DE"
}

variable "plan" {
  description = "Database service plan (essential, business, or enterprise)"
  type        = string
  default     = "essential"
}

variable "flavor" {
  description = "Database instance flavor"
  type        = string
  default     = "db1-4"
}

variable "database_name" {
  description = "Name of the application database"
  type        = string
  default     = "app"
}

variable "database_username" {
  description = "PostgreSQL username"
  type        = string
  default     = "app"
}

variable "ip_restrictions" {
  description = "List of IP restrictions for database access"
  type = list(object({
    ip          = string
    description = string
  }))
  default = []
}

variable "environment" {
  description = "Environment name for the database"
  type        = string
  default     = "production"
}
