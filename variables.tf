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
  description = "List of availability zones for subnet placement (e.g., [\"us-east-2a\", \"us-east-2b\"])"
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

variable "create_vault_aws_interface_endpoints" {
  description = "Create interface VPC endpoints in the Vault (IAM, STS, EC2, ELB, KMS, autoscaling, Route53) so OCP can use AWS APIs without NAT/IGW. Strongly recommended for air-gapped Vault + default CCO mint mode."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# OCP UPI (Optional)
# -----------------------------------------------------------------------------
variable "ocp_cluster_name" {
  description = "OpenShift cluster name for UPI deployment"
  type        = string
  default     = "gryphon-ocp"
}

variable "create_ingress_certificate" {
  description = "When true, create ACM certificate for OpenShift ingress (*.apps.<cluster>.<domain>). Requires route53_hosted_zone_name for public certs, or use_ingress_private_ca for internal domains."
  type        = bool
  default     = false
}

variable "use_ingress_private_ca" {
  description = "When true with create_ingress_certificate, use ACM Private CA (for internal domains like fsi.internal). When false, use public ACM with DNS validation."
  type        = bool
  default     = false
}

variable "ocp_ingress_base_domain" {
  description = "Base domain for ingress certificate (e.g., fsi.internal). When empty, uses route53_hosted_zone_name. Use for internal domains when route53 zone differs."
  type        = string
  default     = ""
}

variable "ocp_version" {
  description = "OpenShift/RHCOS version for AMI import (e.g., 4.20, 4.21)"
  type        = string
  default     = "4.20"
}

# -----------------------------------------------------------------------------
# RHCOS AMI Import (disconnected/locked-down AWS)
# -----------------------------------------------------------------------------
variable "create_rhcos_ami" {
  description = "When true, create RHCOS AMI import infrastructure and optionally import. Set false to skip (e.g. using Marketplace or manual copy)."
  type        = bool
  default     = true
}

variable "import_rhcos_ami" {
  description = "When true, import RHCOS from mirror.openshift.com into your account. Requires curl, aws CLI; takes ~15-20 min. Set false if AMI already exists or to skip import."
  type        = bool
  default     = true
}

variable "rhcos_mirror_base" {
  description = "RHCOS mirror path (e.g. '4.20/latest' or 'latest'). Empty defaults to ocp_version/latest."
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Route53 (Optional - for sandbox hosted zone from Red Hat Demo Platform)
# -----------------------------------------------------------------------------
variable "route53_hosted_zone_name" {
  description = "Route53 hosted zone name (e.g. sandbox.example.com). When set, creates bastion.<zone> A record. Used as the OCP DNS zone when ocp_base_domain is empty or when ocp_base_domain matches this zone name (same normalized FQDN). Leave empty to skip."
  type        = string
  default     = ""
}

variable "ocp_base_domain" {
  description = "Base domain for OCP (must match gryphon-forge base_domain). Foundry sets create_ocp_private_zone true and creates a private hosted zone (Nest + Vault associated) when this is non-empty AND (route53_hosted_zone_name is empty OR the normalized names differ). Otherwise OCP uses the existing zone from route53_hosted_zone_name. gryphon-forge still creates api/api-int/*.apps records in that zone after load balancers exist."
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Bastion Host
# -----------------------------------------------------------------------------
variable "bastion_key_name" {
  description = "Name of existing EC2 key pair for SSH access to bastion. Create one in AWS Console or via: aws ec2 create-key-pair --key-name <name> --query 'KeyMaterial' --output text > key.pem"
  type        = string
}

variable "bastion_instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "bastion_root_volume_gb" {
  description = "Bastion root EBS volume size (GiB, gp3). Default adds ~20 GiB beyond typical AMI size for oc-mirror workspace and persistence under ec2-user home."
  type        = number
  default     = 28
}

variable "bastion_ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion. Restrict to VPN or office IP for security."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "bastion_oc_cli_version" {
  description = "OpenShift CLI / oc-mirror release channel on bastion (e.g. stable-4.20, 4.20.0, latest-4.20). When empty, uses stable-<ocp_version> so oc and oc-mirror match ocp_version."
  type        = string
  default     = ""
}

variable "oc_mirror_pull_secret_path" {
  description = "Path on the bastion to the Red Hat pull secret JSON (copy from cloud.redhat.com). Tilde (~) expands to the SSH user's home. Used by /etc/profile.d/gryphon-oc-mirror.sh and gryphon_oc_mirror()."
  type        = string
  default     = "~/.openshift/pull-secret"
}

# -----------------------------------------------------------------------------
# Mirror Registry (disconnected OCP install)
# -----------------------------------------------------------------------------
variable "create_mirror_registry" {
  description = "When true, deploy mirror registry EC2 in Nest for disconnected OCP install. Run oc-mirror from bastion to populate."
  type        = bool
  default     = true
}

variable "mirror_registry_instance_type" {
  description = "EC2 instance type for mirror registry host"
  type        = string
  default     = "t3.medium"
}

variable "mirror_registry_root_volume_gb" {
  description = "Mirror registry EC2 root EBS volume size (GiB, gp3). Holds /opt/registry/data; use 500+ for full OCP + operators + graph mirroring."
  type        = number
  default     = 500
}

variable "mirror_registry_tls_extra_san_dns_names" {
  description = "Extra DNS SANs on the mirror registry TLS certificate (mirror.<base_domain> is always included). Use for aliases."
  type        = list(string)
  default     = []
}
