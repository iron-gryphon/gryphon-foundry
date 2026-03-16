# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------
output "nest_vpc_id" {
  description = "ID of the Nest (connected) VPC"
  value       = module.vpc.nest_vpc_id
}

output "nest_public_subnet_ids" {
  description = "IDs of Nest public subnets"
  value       = module.vpc.nest_public_subnet_ids
}

output "vault_vpc_id" {
  description = "ID of the Vault (isolated) VPC"
  value       = module.vpc.vault_vpc_id
}

output "vault_private_subnet_ids" {
  description = "IDs of Vault private subnets"
  value       = module.vpc.vault_private_subnet_ids
}

# -----------------------------------------------------------------------------
# Security Outputs
# -----------------------------------------------------------------------------
output "sneakernet_kms_key_arn" {
  description = "ARN of KMS key for Sneakernet encryption"
  value       = module.security.sneakernet_kms_key_arn
}

output "vault_security_group_id" {
  description = "Security group ID for Vault"
  value       = module.security.vault_security_group_id
}

output "vault_api_security_group_id" {
  description = "Security group ID for Vault API/ingress"
  value       = module.security.vault_api_security_group_id
}

# -----------------------------------------------------------------------------
# Sneakernet Outputs
# -----------------------------------------------------------------------------
output "nest_staging_bucket_name" {
  description = "Nest staging S3 bucket (oc-mirror, datasets)"
  value       = module.sneakernet.nest_staging_bucket_name
}

output "vault_receiving_bucket_name" {
  description = "Vault receiving S3 bucket (air-gapped destination)"
  value       = module.sneakernet.vault_receiving_bucket_name
}

# -----------------------------------------------------------------------------
# OCP UPI Outputs
# -----------------------------------------------------------------------------
output "ocp_upi_subnet_ids" {
  description = "Subnet IDs for OCP UPI deployment"
  value       = module.ocp_upi.vault_private_subnet_ids
}
