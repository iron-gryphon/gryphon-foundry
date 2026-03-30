# Sneakernet Module: EBS/S3 Bridge for Air-Gap Data Transfer
# Manages staging buckets and VPC endpoints for manual/automated data movement
# between Nest (connected) and Vault (isolated)

data "aws_partition" "current" {}

locals {
  # IAM control plane region for interface PrivateLink (not the VPC region).
  # See https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-cross-region-privatelink-support.html
  iam_interface_service_region = (
    data.aws_partition.current.partition == "aws-cn" ? "cn-north-1" :
    data.aws_partition.current.partition == "aws-us-gov" ? "us-gov-west-1" :
    "us-east-1"
  )

  # Route 53 API PrivateLink (commercial only): service is cross-Region; home Region is us-east-1.
  # See https://aws.amazon.com/about-aws/whats-new/2025/11/amazon-route-53-dns-service-aws-privatelink/
  route53_privatelink_supported    = data.aws_partition.current.partition == "aws"
  route53_interface_service_region = "us-east-1"

  # Interface endpoints: AWS APIs reachable privately inside the Vault VPC.
  # IAM and Route 53 use cross-Region PrivateLink (service_region, not com.amazonaws.<vpc-region>.<svc>).
  # S3 uses a separate gateway endpoint below.
  vault_aws_interface_endpoint_specs = merge(
    {
      iam = {
        service_name   = "com.amazonaws.iam"
        service_region = local.iam_interface_service_region
      }
      sts = {
        service_name = "com.amazonaws.${var.aws_region}.sts"
      }
      ec2 = {
        service_name = "com.amazonaws.${var.aws_region}.ec2"
      }
      elasticloadbalancing = {
        service_name = "com.amazonaws.${var.aws_region}.elasticloadbalancing"
      }
      kms = {
        service_name = "com.amazonaws.${var.aws_region}.kms"
      }
      autoscaling = {
        service_name = "com.amazonaws.${var.aws_region}.autoscaling"
      }
    },
    local.route53_privatelink_supported ? {
      route53 = {
        service_name   = "com.amazonaws.route53"
        service_region = local.route53_interface_service_region
      }
    } : {}
  )
}

# -----------------------------------------------------------------------------
# S3 Bucket: Nest Staging (oc-mirror output, datasets)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "nest_staging" {
  bucket = "${var.environment}-nest-staging-${var.aws_account_id}"

  tags = merge(var.tags, {
    Name = "${var.environment}-nest-staging"
    Role = "sneakernet-nest"
  })
}

resource "aws_s3_bucket_versioning" "nest_staging" {
  bucket = aws_s3_bucket.nest_staging.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "nest_staging" {
  bucket = aws_s3_bucket.nest_staging.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.sneakernet_kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "nest_staging" {
  bucket = aws_s3_bucket.nest_staging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# S3 Bucket: Vault Receiving (air-gapped destination)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "vault_receiving" {
  bucket = "${var.environment}-vault-receiving-${var.aws_account_id}"

  tags = merge(var.tags, {
    Name = "${var.environment}-vault-receiving"
    Role = "sneakernet-vault"
  })
}

resource "aws_s3_bucket_versioning" "vault_receiving" {
  bucket = aws_s3_bucket.vault_receiving.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vault_receiving" {
  bucket = aws_s3_bucket.vault_receiving.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.sneakernet_kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "vault_receiving" {
  bucket = aws_s3_bucket.vault_receiving.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# S3 VPC Gateway Endpoint in Vault - Enables S3 access without IGW/NAT
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "vault_s3" {
  vpc_id            = var.vault_vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = var.vault_route_table_ids

  tags = merge(var.tags, {
    Name = "${var.environment}-vault-s3-endpoint"
  })
}

# -----------------------------------------------------------------------------
# Interface VPC endpoints: AWS APIs without public internet (air-gapped Vault)
# Private DNS: iam.amazonaws.com, sts.*.amazonaws.com, etc. resolve to these ENIs.
# -----------------------------------------------------------------------------
resource "aws_vpc_endpoint" "vault_aws_interface" {
  for_each = var.create_vault_aws_interface_endpoints ? local.vault_aws_interface_endpoint_specs : {}

  vpc_id              = var.vault_vpc_id
  service_name        = each.value.service_name
  service_region      = try(each.value.service_region, null)
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vault_private_subnet_ids
  security_group_ids  = [var.vault_interface_endpoints_security_group_id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.environment}-vault-endpoint-${each.key}"
  })
}

# -----------------------------------------------------------------------------
# IAM Policy: EBS Snapshot Sharing (for cross-VPC restore)
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "ebs_snapshot_share" {
  name        = "${var.environment}-ebs-snapshot-share"
  description = "Policy for EBS snapshot creation and sharing in Sneakernet workflow"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CreateAndShareSnapshots"
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:DescribeSnapshots",
          "ec2:ModifySnapshotAttribute",
          "ec2:DescribeSnapshotAttribute"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}
