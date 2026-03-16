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

variable "sneakernet_kms_key_arn" {
  description = "ARN of KMS key for S3 bucket encryption"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
