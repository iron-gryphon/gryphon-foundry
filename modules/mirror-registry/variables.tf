# -----------------------------------------------------------------------------
# Mirror Registry Module - Container registry in Nest for disconnected OCP install
# Reachable from Vault via VPC peering. Run oc-mirror from bastion to populate.
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "nest_vpc_id" {
  description = "Nest VPC ID"
  type        = string
}

variable "nest_public_subnet_ids" {
  description = "Nest public subnet IDs"
  type        = list(string)
}

variable "vault_vpc_cidr" {
  description = "Vault VPC CIDR (allowed to pull from registry)"
  type        = string
}

variable "nest_vpc_cidr" {
  description = "Nest VPC CIDR (oc-mirror push from bastion)"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair for SSH"
  type        = string
}

variable "base_domain" {
  description = "Base domain for mirror.<base_domain> DNS record"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for mirror.<base_domain> record (optional)"
  type        = string
  default     = ""
}

variable "create_route53_record" {
  description = "When true, create Route53 A record for mirror.<base_domain>. Use this for count (plan-time known); hosted_zone_id may be unknown until apply."
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "EC2 instance type for registry host"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_gb" {
  description = "Size of the root EBS volume (gp3) in GiB. Registry data lives under /opt/registry/data on this volume; OCP release + operators + graph need hundreds of GiB."
  type        = number
  default     = 500
}

variable "mirror_registry_tls_extra_san_dns_names" {
  description = "Extra DNS names for the registry TLS certificate SAN extension. mirror.<base_domain> is always included."
  type        = list(string)
  default     = []
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to registry host"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
