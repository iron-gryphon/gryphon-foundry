# gryphon-foundry: Air-Gapped FSI AI/ML Infrastructure
# Dual-VPC architecture: Nest (connected) + Vault (isolated)

provider "aws" {
  region = var.aws_region

  # Credentials: Use default credential chain (env vars, ~/.aws/credentials, IAM role)
  # Do NOT pass credentials via variables. See terraform.tfvars.example for setup.
  default_tags {
    tags = merge(var.tags, {
      Project     = "gryphon-foundry"
      Environment = var.environment
    })
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# VPC Module: Nest + Vault
# -----------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  environment                = var.environment
  nest_vpc_cidr              = var.nest_vpc_cidr
  nest_public_subnet_cidrs   = var.nest_public_subnet_cidrs
  vault_vpc_cidr             = var.vault_vpc_cidr
  vault_private_subnet_cidrs = var.vault_private_subnet_cidrs
  availability_zones         = var.availability_zones
  tags                       = var.tags
}

# -----------------------------------------------------------------------------
# Security Module: KMS, Security Groups
# -----------------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  environment              = var.environment
  nest_vpc_id              = module.vpc.nest_vpc_id
  nest_vpc_cidr            = module.vpc.nest_vpc_cidr
  vault_vpc_id             = module.vpc.vault_vpc_id
  vault_vpc_cidr           = module.vpc.vault_vpc_cidr
  kms_deletion_window_days = var.kms_deletion_window_days
  tags                     = var.tags
}

# -----------------------------------------------------------------------------
# Sneakernet Module: S3 Bridge, VPC Endpoints
# -----------------------------------------------------------------------------
module "sneakernet" {
  source = "./modules/sneakernet"

  environment            = var.environment
  aws_region             = data.aws_region.current.name
  aws_account_id         = data.aws_caller_identity.current.account_id
  vault_vpc_id           = module.vpc.vault_vpc_id
  vault_route_table_ids  = [module.vpc.vault_route_table_id]
  sneakernet_kms_key_arn = module.security.sneakernet_kms_key_arn
  tags                   = var.tags
}

# -----------------------------------------------------------------------------
# OCP UPI Module: Placeholder for Ignition-based deployment
# -----------------------------------------------------------------------------
module "ocp_upi" {
  source = "./modules/ocp-upi"

  environment                 = var.environment
  vault_private_subnet_ids    = module.vpc.vault_private_subnet_ids
  vault_api_security_group_id = module.security.vault_api_security_group_id
  vault_security_group_id     = module.security.vault_security_group_id
  cluster_name                = var.ocp_cluster_name
  control_plane               = var.ocp_control_plane
  worker                      = var.ocp_worker
  gpu_worker                  = var.ocp_gpu_worker
  tags                        = var.tags
}

# -----------------------------------------------------------------------------
# Bastion Module: Internet-accessible jump host with OCP CLI
# -----------------------------------------------------------------------------
module "bastion" {
  source = "./modules/bastion"

  environment            = var.environment
  nest_vpc_id            = module.vpc.nest_vpc_id
  nest_public_subnet_ids = module.vpc.nest_public_subnet_ids
  key_name               = var.bastion_key_name
  instance_type          = var.bastion_instance_type
  ssh_allowed_cidrs      = var.bastion_ssh_allowed_cidrs
  oc_cli_version         = var.bastion_oc_cli_version
  tags                   = var.tags
}
