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

variable "control_plane" {
  description = "Control plane node configuration"
  type = object({
    count            = number
    instance_type    = string
    root_volume_size = number
  })
}

variable "worker" {
  description = "Standard worker node configuration"
  type = object({
    count            = number
    instance_type    = string
    root_volume_size = number
  })
}

variable "gpu_worker" {
  description = "GPU worker node configuration"
  type = object({
    count            = number
    instance_type    = string
    root_volume_size = number
  })
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
