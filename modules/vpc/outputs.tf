output "nest_vpc_id" {
  description = "ID of the Nest (connected) VPC"
  value       = aws_vpc.nest.id
}

output "nest_vpc_cidr" {
  description = "CIDR block of the Nest VPC"
  value       = aws_vpc.nest.cidr_block
}

output "nest_public_subnet_ids" {
  description = "IDs of Nest public subnets"
  value       = aws_subnet.nest_public[*].id
}

output "nest_public_subnet_cidrs" {
  description = "CIDR blocks of Nest public subnets"
  value       = aws_subnet.nest_public[*].cidr_block
}

output "vault_vpc_id" {
  description = "ID of the Vault (isolated) VPC"
  value       = aws_vpc.vault.id
}

output "vault_vpc_cidr" {
  description = "CIDR block of the Vault VPC"
  value       = aws_vpc.vault.cidr_block
}

output "vault_private_subnet_ids" {
  description = "IDs of Vault private subnets"
  value       = aws_subnet.vault_private[*].id
}

output "vault_private_subnet_cidrs" {
  description = "CIDR blocks of Vault private subnets"
  value       = aws_subnet.vault_private[*].cidr_block
}

output "vault_route_table_id" {
  description = "ID of the Vault private route table (for S3 endpoint)"
  value       = aws_route_table.vault_private.id
}
