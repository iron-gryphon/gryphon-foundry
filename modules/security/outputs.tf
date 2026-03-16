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
  description = "ID of the Vault security group"
  value       = aws_security_group.vault.id
}

output "vault_api_security_group_id" {
  description = "ID of the Vault API/ingress security group"
  value       = aws_security_group.vault_api.id
}
