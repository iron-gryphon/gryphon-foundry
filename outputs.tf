# -----------------------------------------------------------------------------
# Region (required by gryphon-forge for AWS API calls)
# -----------------------------------------------------------------------------
output "region" {
  description = "AWS region for the deployment. Pass to gryphon-forge as foundry_region."
  value       = data.aws_region.current.region
}

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

output "nest_vpc_cidr" {
  description = "CIDR block of the Nest VPC (for gryphon-forge bootstrap SG - bastion reaches OCP API from Nest via peering)"
  value       = module.vpc.nest_vpc_cidr
}

output "vault_vpc_id" {
  description = "ID of the Vault (isolated) VPC"
  value       = module.vpc.vault_vpc_id
}

output "vault_vpc_cidr" {
  description = "CIDR block of the Vault VPC (used by OpenShift install-config networking.machineNetwork)"
  value       = module.vpc.vault_vpc_cidr
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
# OCP UPI Outputs (consumed by the UPI project)
# -----------------------------------------------------------------------------
output "ocp_upi_subnet_ids" {
  description = "Subnet IDs for OCP UPI deployment (Vault private subnets)"
  value       = module.ocp_upi.vault_private_subnet_ids
}

output "ocp_cluster_name" {
  description = "OpenShift cluster name for UPI (used in api.<cluster>.<domain>)"
  value       = module.ocp_upi.cluster_name
}

output "ocp_base_domain" {
  description = "Base domain for OCP DNS (Route53 hosted zone). Empty if not configured. Pass to gryphon-forge as base_domain."
  value       = local.ocp_base_domain_effective
}

output "internal_hosted_zone_id" {
  description = "Route53 hosted zone ID for OCP DNS records (api, api-int, *.apps). Pass to gryphon-forge as foundry_internal_hosted_zone_id."
  value       = local.create_ocp_private_zone ? aws_route53_zone.ocp_internal[0].zone_id : (var.route53_hosted_zone_name != "" ? data.aws_route53_zone.ocp[0].id : null)
}

output "rhcos_ami_id" {
  description = "RHCOS AMI ID (Option B: imported from mirror.openshift.com). Pass to gryphon-forge as rhcos_ami_id."
  value       = var.create_rhcos_ami ? module.rhcos_ami[0].rhcos_ami_id : null
}

# -----------------------------------------------------------------------------
# Bastion Outputs
# -----------------------------------------------------------------------------
output "bastion_security_group_id" {
  description = "Security group ID of the bastion host (for gryphon-forge bootstrap SG rules allowing API/MCS from bastion)"
  value       = module.bastion.bastion_security_group_id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host (external route for SSH and OCP CLI)"
  value       = module.bastion.bastion_public_ip
}

output "bastion_public_dns" {
  description = "Public DNS name of the bastion host"
  value       = module.bastion.bastion_public_dns
}

output "bastion_ssh_command" {
  description = "SSH command to connect to the bastion"
  value       = module.bastion.bastion_ssh_command
}

output "bastion_hostname" {
  description = "Bastion hostname (bastion.<zone>) when Route53 hosted zone is configured"
  value       = module.bastion.bastion_hostname
}

output "oc_mirror_pull_secret_path" {
  description = "Path on bastion for the Red Hat pull secret (copy JSON here; used by gryphon_oc_mirror and oc mirror --authfile)"
  value       = var.oc_mirror_pull_secret_path
}

output "bastion_oc_release" {
  description = "OpenShift client and oc-mirror release channel installed on bastion (mirror.openshift.com/clients/ocp/<channel>/...)"
  value       = local.bastion_oc_release
}

# -----------------------------------------------------------------------------
# Mirror Registry Outputs (disconnected OCP)
# -----------------------------------------------------------------------------
output "mirror_registry_url" {
  description = "Mirror registry URL for gryphon-forge (mirror.<base_domain>). Add to install-config imageContentSources."
  value       = var.create_mirror_registry && local.ocp_base_domain_effective != "" ? module.mirror_registry[0].mirror_registry_url : null
}

output "mirror_registry_public_ip" {
  description = "Public IP of mirror registry (for oc-mirror from outside VPC)"
  value       = var.create_mirror_registry && local.ocp_base_domain_effective != "" ? module.mirror_registry[0].mirror_registry_public_ip : null
}

output "mirror_registry_additional_trust_bundle" {
  description = "PEM CA for the mirror registry TLS cert (install-config additionalTrustBundle). Set automatically from Terraform when create_mirror_registry is true."
  value       = var.create_mirror_registry && local.ocp_base_domain_effective != "" ? module.mirror_registry[0].mirror_registry_additional_trust_bundle : null
}

# -----------------------------------------------------------------------------
# ACM Outputs (consumed by gryphon-forge for ALB HTTPS)
# -----------------------------------------------------------------------------
output "ingress_certificate_arn" {
  description = "ARN of ACM certificate for OpenShift ingress (*.apps.<cluster>.<domain>). Pass to gryphon-forge as foundry_ingress_certificate_arn."
  value       = var.create_ingress_certificate ? module.acm[0].ingress_certificate_arn : null
}
