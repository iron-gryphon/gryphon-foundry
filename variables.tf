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

# -----------------------------------------------------------------------------
# OCP Node Configuration
# -----------------------------------------------------------------------------
variable "ocp_control_plane" {
  description = "Control plane node configuration (masters)"
  type = object({
    count            = number
    instance_type    = string
    root_volume_size = number
  })
  default = {
    count            = 3
    instance_type    = "m5.xlarge" # 4 vCPU, 16GB RAM
    root_volume_size = 120
  }
}

variable "ocp_worker" {
  description = "Standard worker node configuration"
  type = object({
    count            = number
    instance_type    = string
    root_volume_size = number
  })
  default = {
    count            = 2
    instance_type    = "m5.xlarge" # 4 vCPU, 16GB RAM
    root_volume_size = 120
  }
}

variable "ocp_gpu_worker" {
  description = "GPU worker node configuration (NVIDIA T4). Set count to 0 to disable."
  type = object({
    count            = number
    instance_type    = string
    root_volume_size = number
  })
  default = {
    count            = 2
    instance_type    = "g4dn.xlarge" # 4 vCPU, 16GB RAM, 1x NVIDIA T4
    root_volume_size = 120
  }
}

# -----------------------------------------------------------------------------
# Route53 (Optional - for sandbox hosted zone from Red Hat Demo Platform)
# -----------------------------------------------------------------------------
variable "route53_hosted_zone_name" {
  description = "Route53 hosted zone name (e.g. sandbox.example.com) from the sandbox environment. When set, creates bastion.<zone> A record. Leave empty to skip."
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

variable "bastion_ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion. Restrict to VPN or office IP for security."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "bastion_oc_cli_version" {
  description = "OpenShift CLI version to install on bastion (e.g. 4.15.0, stable)"
  type        = string
  default     = "stable"
}
