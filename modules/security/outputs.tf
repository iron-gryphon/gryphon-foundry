output "sneakernet_kms_key_id" {
  description = "ID of the KMS key for Sneakernet encryption"
  value       = aws_kms_key.sneakernet.id
}

output "sneakernet_kms_key_arn" {
  description = "ARN of the KMS key for Sneakernet encryption"
  value       = aws_kms_key.sneakernet.arn
}

output "nest_security_group_id" {
  description = "ID of the Nest security group"
  value       = aws_security_group.nest.id
}

output "vault_security_group_id" {
  description = "Vault VPC default SG: broad TCP/UDP ingress+egress within vault_vpc_cidr. Attach to nodes that need general intra-VPC connectivity; pair with vault_api when API/MCS/bootstrap etcd rules are required."
  value       = aws_security_group.vault.id
}

output "vault_api_security_group_id" {
  description = "API 6443, MCS 22623, HTTP/S ingress, and bootstrap etcd 2379-2380 from vault_vpc_cidr only. If this is the only SG on bootstrap/masters/NLB targets, it now allows master→bootstrap etcd; do not rely on Nest for etcd."
  value       = aws_security_group.vault_api.id
}

output "vault_interface_endpoints_security_group_id" {
  description = "Security group for AWS interface VPC endpoints in Vault (IAM, STS, EC2, ELB, …)"
  value       = aws_security_group.vault_interface_endpoints.id
}
