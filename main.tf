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

# Effective OCP base domain: ocp_base_domain when set, else route53_hosted_zone_name
locals {
  # OpenShift client + oc-mirror tarball channel (mirror.openshift.com/clients/ocp/<channel>/...)
  bastion_oc_release = var.bastion_oc_cli_version != "" ? var.bastion_oc_cli_version : "stable-${var.ocp_version}"

  ocp_base_domain_effective = coalesce(
    var.ocp_base_domain != "" ? var.ocp_base_domain : null,
    var.route53_hosted_zone_name != "" ? trimsuffix(var.route53_hosted_zone_name, ".") : null,
    ""
  )
  # Create private hosted zone when: internal domain (e.g. fsi.internal) that differs from sandbox zone, or is the only domain set
  create_ocp_private_zone = var.ocp_base_domain != "" && (
    var.route53_hosted_zone_name == "" || trimsuffix(var.ocp_base_domain, ".") != trimsuffix(var.route53_hosted_zone_name, ".")
  )
}

# Private hosted zone for internal OCP domain (e.g. fsi.internal) when it differs from sandbox zone
# Associated with both Vault (OCP nodes) and Nest (bastion) VPCs so the bastion can resolve
# api.<cluster>.<domain> during bootstrap and oc login.
resource "aws_route53_zone" "ocp_internal" {
  count = local.create_ocp_private_zone ? 1 : 0

  name = "${trimsuffix(var.ocp_base_domain, ".")}."

  vpc {
    vpc_id = module.vpc.vault_vpc_id
  }

  vpc {
    vpc_id = module.vpc.nest_vpc_id
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-ocp-internal-${replace(trimsuffix(var.ocp_base_domain, "."), ".", "-")}"
  })
}

# Route53 zone for UPI DNS records (api, api-int, *.apps) - use existing zone when not creating internal
data "aws_route53_zone" "ocp" {
  count = var.route53_hosted_zone_name != "" && !local.create_ocp_private_zone ? 1 : 0

  name = var.route53_hosted_zone_name
}

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
  aws_region             = data.aws_region.current.region
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
  tags                        = var.tags
}

# -----------------------------------------------------------------------------
# RHCOS AMI Import (for disconnected/locked-down AWS)
# Imports RHCOS from mirror.openshift.com when account cannot use Red Hat AMIs
# Set create_rhcos_ami = false to skip (e.g. using Marketplace or Option 1)
# -----------------------------------------------------------------------------
module "rhcos_ami" {
  source = "./modules/rhcos-ami"

  count = var.create_rhcos_ami ? 1 : 0

  environment       = var.environment
  aws_region        = data.aws_region.current.region
  aws_account_id    = data.aws_caller_identity.current.account_id
  ocp_version       = var.ocp_version
  import_rhcos_ami  = var.import_rhcos_ami
  rhcos_mirror_base = var.rhcos_mirror_base
  tags              = var.tags
}

# -----------------------------------------------------------------------------
# ACM Module: Ingress certificate for OpenShift (*.apps.<cluster>.<domain>)
# -----------------------------------------------------------------------------
module "acm" {
  count = var.create_ingress_certificate ? 1 : 0

  source = "./modules/acm"

  environment              = var.environment
  cluster_name             = var.ocp_cluster_name
  base_domain              = coalesce(var.ocp_ingress_base_domain, var.route53_hosted_zone_name)
  route53_hosted_zone_name = var.use_ingress_private_ca ? "" : var.route53_hosted_zone_name
  use_private_ca           = var.use_ingress_private_ca
  tags                     = var.tags
}

# -----------------------------------------------------------------------------
# Bastion Module: Internet-accessible jump host with OCP CLI
# -----------------------------------------------------------------------------
module "bastion" {
  source = "./modules/bastion"

  environment                = var.environment
  nest_vpc_id                = module.vpc.nest_vpc_id
  nest_public_subnet_ids     = module.vpc.nest_public_subnet_ids
  key_name                   = var.bastion_key_name
  instance_type              = var.bastion_instance_type
  ssh_allowed_cidrs          = var.bastion_ssh_allowed_cidrs
  oc_release                 = local.bastion_oc_release
  oc_mirror_pull_secret_path = var.oc_mirror_pull_secret_path
  route53_hosted_zone_name   = var.route53_hosted_zone_name
  tags                       = var.tags
}

# -----------------------------------------------------------------------------
# Mirror Registry Module: Container registry in Nest for disconnected OCP
# Vault pulls images via VPC peering. Run oc-mirror from bastion to populate.
# -----------------------------------------------------------------------------
module "mirror_registry" {
  count = var.create_mirror_registry && local.ocp_base_domain_effective != "" ? 1 : 0

  source = "./modules/mirror-registry"

  environment                             = var.environment
  nest_vpc_id                             = module.vpc.nest_vpc_id
  nest_public_subnet_ids                  = module.vpc.nest_public_subnet_ids
  nest_vpc_cidr                           = module.vpc.nest_vpc_cidr
  vault_vpc_cidr                          = module.vpc.vault_vpc_cidr
  key_name                                = var.bastion_key_name
  base_domain                             = local.ocp_base_domain_effective
  instance_type                           = var.mirror_registry_instance_type
  mirror_registry_tls_extra_san_dns_names = var.mirror_registry_tls_extra_san_dns_names
  ssh_allowed_cidrs                       = var.bastion_ssh_allowed_cidrs
  hosted_zone_id                          = local.create_ocp_private_zone ? aws_route53_zone.ocp_internal[0].zone_id : ""
  create_route53_record                   = local.create_ocp_private_zone
  tags                                    = var.tags
}
