# -----------------------------------------------------------------------------
# Environment & Naming
# -----------------------------------------------------------------------------
variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
  default     = "sandbox"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region for the deployment"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones for subnet placement (e.g., [\"us-east-1a\", \"us-east-1b\"])"
  type        = list(string)
}

# -----------------------------------------------------------------------------
# Nest VPC (Connected)
# -----------------------------------------------------------------------------
variable "nest_vpc_cidr" {
  description = "CIDR block for the Nest (connected) VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "nest_public_subnet_cidrs" {
  description = "CIDR blocks for Nest public subnets (one per AZ)"
  type        = list(string)
}

# -----------------------------------------------------------------------------
# Vault VPC (Isolated)
# -----------------------------------------------------------------------------
variable "vault_vpc_cidr" {
  description = "CIDR block for the Vault (isolated) VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "vault_private_subnet_cidrs" {
  description = "CIDR blocks for Vault private subnets (one per AZ)"
  type        = list(string)
}

# -----------------------------------------------------------------------------
# Security
# -----------------------------------------------------------------------------
variable "kms_deletion_window_days" {
  description = "Number of days to retain KMS key after deletion request"
  type        = number
  default     = 7
}

# -----------------------------------------------------------------------------
# OCP UPI (Optional)
# -----------------------------------------------------------------------------
variable "ocp_cluster_name" {
  description = "OpenShift cluster name for UPI deployment"
  type        = string
  default     = "gryphon-ocp"
}
