# --- OVH Provider Configuration ---

variable "ovh_endpoint" {
  description = "OVH API endpoint"
  type        = string
  default     = "ovh-ca"
}

variable "ovh_application_key" {
  description = "OVH application key"
  type        = string
  sensitive   = true
}

variable "ovh_application_secret" {
  description = "OVH application secret"
  type        = string
  sensitive   = true
}

variable "ovh_consumer_key" {
  description = "OVH consumer key"
  type        = string
  sensitive   = true
}

# --- OpenStack Provider Configuration ---

variable "openstack_auth_url" {
  description = "OpenStack authentication URL"
  type        = string
}

variable "openstack_user_name" {
  description = "OpenStack username"
  type        = string
  sensitive   = true
}

variable "openstack_password" {
  description = "OpenStack password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "openstack_token" {
  description = "OpenStack token (alternative to username/password)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "openstack_tenant_name" {
  description = "OpenStack tenant name (project ID)"
  type        = string
}

# --- Cluster Configuration ---

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "domain" {
  description = "Base domain for the cluster. Used to derive globally-unique OVH Object Storage bucket names for Loki when enable_object_storage is true."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_object_storage || var.domain != ""
    error_message = "domain must be set when enable_object_storage is true (OVH Object Storage bucket names are globally unique)."
  }
}

variable "region" {
  description = "OVH region for the cluster (OpenStack region, e.g. GRA9, SBG5, DE1, BHS5)."
  type        = string
  default     = "GRA9"
}

variable "subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "192.168.100.0/24"
}

# --- Node Pool Configuration ---

variable "node_flavor" {
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

# --- OIDC Configuration ---

variable "enable_oidc" {
  description = "Enable OIDC authentication for the cluster"
  type        = bool
  default     = false
}

variable "oidc_client_id" {
  description = "OIDC client ID"
  type        = string
  default     = ""
}

variable "oidc_client_secret" {
  description = "OIDC client secret (not used by the module, but documented for reference)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL"
  type        = string
  default     = "https://accounts.google.com"
}

variable "oidc_username_claim" {
  description = "OIDC username claim"
  type        = string
  default     = "email"
}

variable "oidc_groups_claim" {
  description = "OIDC groups claim"
  type        = list(string)
  default     = ["groups"]
}

variable "oidc_username_prefix" {
  description = "OIDC username prefix"
  type        = string
  default     = "oidc:"
}

# --- Database Configuration ---

variable "database_provider" {
  description = "Database provider: 'managed' for OVH managed PostgreSQL, 'cnpg' for CloudNativePG, 'none' for no database"
  type        = string
  default     = "none"
  validation {
    condition     = contains(["managed", "cnpg", "none"], var.database_provider)
    error_message = "database_provider must be one of: managed, cnpg, none"
  }
}

variable "database_region" {
  description = "OVH region for the database"
  type        = string
  default     = ""
}

variable "database_plan" {
  description = "Database service plan (essential, business, or enterprise)"
  type        = string
  default     = "essential"
}

variable "database_flavor" {
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
  description = "Username for the application database user"
  type        = string
  default     = "app"
}

variable "database_ip_restrictions" {
  description = "List of IP restrictions for database access"
  type = list(object({
    ip          = string
    description = string
  }))
  default = []
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "enable_object_storage" {
  description = "Enable OVH Object Storage for Loki"
  type        = bool
  default     = true
}

variable "storage_region" {
  description = "OVH S3 storage region (GRA, SBG, BHS). Defaults to base region without AZ suffix."
  type        = string
  default     = ""
}

variable "api_server_ip_restrictions" {
  description = "List of CIDR blocks allowed to access the Kubernetes API server. Empty list means unrestricted."
  type        = list(string)
  default     = []
}
