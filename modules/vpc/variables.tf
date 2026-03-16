variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "nest_vpc_cidr" {
  description = "CIDR block for the Nest (connected) VPC"
  type        = string
}

variable "nest_public_subnet_cidrs" {
  description = "CIDR blocks for Nest public subnets (one per AZ)"
  type        = list(string)
}

variable "vault_vpc_cidr" {
  description = "CIDR block for the Vault (isolated) VPC"
  type        = string
}

variable "vault_private_subnet_cidrs" {
  description = "CIDR blocks for Vault private subnets (one per AZ)"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones for subnet placement"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
