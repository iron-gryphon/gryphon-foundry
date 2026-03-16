# Sneakernet Module: EBS/S3 Bridge for Air-Gap Data Transfer
# Manages staging buckets and VPC endpoints for manual/automated data movement
# between Nest (connected) and Vault (isolated)

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
