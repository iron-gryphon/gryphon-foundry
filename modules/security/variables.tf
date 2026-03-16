variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "nest_vpc_id" {
  description = "ID of the Nest VPC"
  type        = string
}

variable "nest_vpc_cidr" {
  description = "CIDR block of the Nest VPC (for bastion access to OCP API)"
  type        = string
}

variable "vault_vpc_id" {
  description = "ID of the Vault VPC"
  type        = string
}

variable "vault_vpc_cidr" {
  description = "CIDR block of the Vault VPC"
  type        = string
}

variable "kms_deletion_window_days" {
  description = "Number of days to retain KMS key after deletion request"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
