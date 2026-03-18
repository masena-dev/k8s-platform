resource "ovh_cloud_project_database" "postgresql" {
  service_name = var.project_id
  description  = "PostgreSQL ${var.environment}"
  engine       = "postgresql"
  version      = "16"
  plan         = var.plan
  flavor       = var.flavor

  nodes {
    region     = var.region
    network_id = var.network_id
    subnet_id  = var.subnet_id
  }

  dynamic "nodes" {
    for_each = var.plan == "business" ? [1] : []
    content {
      region     = var.region
      network_id = var.network_id
      subnet_id  = var.subnet_id
    }
  }

  dynamic "ip_restrictions" {
    for_each = var.ip_restrictions
    content {
      ip          = ip_restrictions.value.ip
      description = ip_restrictions.value.description
    }
  }
}

resource "ovh_cloud_project_database_database" "app_db" {
  service_name = var.project_id
  engine       = ovh_cloud_project_database.postgresql.engine
  cluster_id   = ovh_cloud_project_database.postgresql.id
  name         = var.database_name
}

resource "ovh_cloud_project_database_postgresql_user" "app_user" {
  service_name = var.project_id
  cluster_id   = ovh_cloud_project_database.postgresql.id
  name         = var.database_username
}
