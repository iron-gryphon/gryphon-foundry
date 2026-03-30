variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID (used for unique bucket names)"
  type        = string
}

variable "vault_vpc_id" {
  description = "ID of the Vault VPC"
  type        = string
}

variable "vault_route_table_ids" {
  description = "Route table IDs in Vault VPC for S3 endpoint"
  type        = list(string)
}

variable "vault_private_subnet_ids" {
  description = "Vault private subnet IDs for AWS interface VPC endpoints (one subnet per AZ recommended)"
  type        = list(string)
}

variable "vault_interface_endpoints_security_group_id" {
  description = "Security group ID attached to interface VPC endpoints (ingress 443 from Vault CIDR)"
  type        = string
}

variable "create_vault_aws_interface_endpoints" {
  description = "When true, create interface VPC endpoints in Vault for IAM, STS, EC2, ELB, KMS, autoscaling, Route53 (required for mint-mode CCO and cloud controllers without public internet)"
  type        = bool
  default     = true
}

variable "sneakernet_kms_key_arn" {
  description = "ARN of KMS key for S3 bucket encryption"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
