variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "vault_private_subnet_ids" {
  description = "IDs of Vault private subnets for OCP node placement"
  type        = list(string)
}

variable "vault_api_security_group_id" {
  description = "Security group ID for OCP API/ingress"
  type        = string
}

variable "vault_security_group_id" {
  description = "Security group ID for Vault internal traffic"
  type        = string
}

variable "cluster_name" {
  description = "OpenShift cluster name"
  type        = string
  default     = "gryphon-ocp"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
