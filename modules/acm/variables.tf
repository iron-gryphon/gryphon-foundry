# -----------------------------------------------------------------------------
# ACM Module: Ingress certificates for OpenShift UPI
# Supports: Public ACM (DNS validation) or Private CA (internal domains)
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "cluster_name" {
  description = "OpenShift cluster name (used in *.apps.<cluster>.<domain>)"
  type        = string
}

variable "base_domain" {
  description = "Base domain for ingress (e.g., sandbox.example.com or fsi.internal). For public ACM, must match Route53 zone."
  type        = string
}

variable "route53_hosted_zone_name" {
  description = "Route53 hosted zone name for DNS validation (e.g., sandbox.example.com). Required when use_private_ca = false."
  type        = string
  default     = ""
}

variable "use_private_ca" {
  description = "When true, create ACM Private CA and issue certificate (for internal domains). When false, use public ACM with DNS validation."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
