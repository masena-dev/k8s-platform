output "network_id" {
  description = "ID of the private network"
  value       = openstack_networking_network_v2.private.id
}

output "subnet_id" {
  description = "ID of the private subnet"
  value       = openstack_networking_subnet_v2.private.id
}

output "subnet_cidr" {
  description = "CIDR block of the private subnet"
  value       = openstack_networking_subnet_v2.private.cidr
}
