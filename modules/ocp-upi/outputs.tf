output "vault_private_subnet_ids" {
  description = "Vault private subnet IDs for OCP UPI node placement"
  value       = var.vault_private_subnet_ids
}

output "vault_api_security_group_id" {
  description = "Security group for OCP API server"
  value       = var.vault_api_security_group_id
}

output "vault_security_group_id" {
  description = "Security group for OCP node internal traffic"
  value       = var.vault_security_group_id
}

output "cluster_name" {
  description = "OpenShift cluster name"
  value       = var.cluster_name
}

output "upi_instructions" {
  description = "Summary of UPI deployment steps"
  value       = "Use openshift-install create ignition-configs, then provision EC2 instances in the Vault subnets. Cluster sizing is configured in the UPI project. See scripts/ for oc-mirror and image sync helpers."
}
