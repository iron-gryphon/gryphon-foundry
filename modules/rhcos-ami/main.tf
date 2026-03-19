# -----------------------------------------------------------------------------
# RHCOS AMI Import Module
# Imports RHCOS from mirror.openshift.com to create an AMI in your account.
# Use when your AWS account cannot access Red Hat's AMIs directly.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# S3 Bucket for RHCOS VMDK upload (VM Import reads from here)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "rhcos_import" {
  bucket = "${var.environment}-rhcos-import-${var.aws_account_id}"

  tags = merge(var.tags, {
    Name = "${var.environment}-rhcos-import"
    Role = "rhcos-ami-import"
  })
}

resource "aws_s3_bucket_versioning" "rhcos_import" {
  bucket = aws_s3_bucket.rhcos_import.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "rhcos_import" {
  bucket = aws_s3_bucket.rhcos_import.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# VM Import IAM Role (must be named vmimport per AWS requirements)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "vmimport" {
  name = "vmimport"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vmie.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "vmimport"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "vmimport" {
  name = "vmimport"
  role = aws_iam_role.vmimport.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.rhcos_import.arn,
          "${aws_s3_bucket.rhcos_import.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:ModifySnapshotAttribute",
          "ec2:CopySnapshot",
          "ec2:RegisterImage",
          "ec2:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Import RHCOS VMDK and create AMI (runs on terraform apply)
# Requires: curl, aws CLI, jq. Takes ~15-20 minutes.
# -----------------------------------------------------------------------------
locals {
  mirror_path   = var.rhcos_mirror_base != "" ? var.rhcos_mirror_base : "${var.ocp_version}/latest"
  vmdk_gz_name  = "rhcos-aws.x86_64.vmdk.gz"
  vmdk_filename = "rhcos-aws.x86_64.vmdk"
  vmdk_gz_url   = "https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${local.mirror_path}/${local.vmdk_gz_name}"
  ami_name      = "rhcos-${var.ocp_version}-openShift-upi"
}

# Import RHCOS VMDK and create AMI. Idempotency handled in script (skips if AMI exists).
resource "null_resource" "import_rhcos" {
  count = var.import_rhcos_ami ? 1 : 0

  triggers = {
    vmdk_url = local.vmdk_gz_url
    bucket   = aws_s3_bucket.rhcos_import.id
    region   = var.aws_region
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      WORK_DIR="$${TMPDIR:-/tmp}/rhcos-import-$${USER}"
      mkdir -p "$${WORK_DIR}"
      cd "$${WORK_DIR}"

      VMDK_GZ="${local.vmdk_gz_name}"
      VMDK="${local.vmdk_filename}"
      BUCKET="${aws_s3_bucket.rhcos_import.id}"
      REGION="${var.aws_region}"
      AMI_NAME="${local.ami_name}"
      AWS_ACCOUNT_ID="${var.aws_account_id}"

      echo "=== RHCOS AMI Import ==="
      EXISTING_AMI=$(aws ec2 describe-images --region "$${REGION}" --owners "$${AWS_ACCOUNT_ID}" \
        --filters "Name=name,Values=$${AMI_NAME}" --query 'Images[0].ImageId' --output text 2>/dev/null || true)
      if [ -n "$${EXISTING_AMI}" ] && [ "$${EXISTING_AMI}" != "None" ]; then
        echo "AMI already exists: $${EXISTING_AMI} (skipping import)"
        exit 0
      fi

      echo "Downloading from ${local.vmdk_gz_url} ..."

      if [ ! -f "$${VMDK}" ]; then
        curl -sSL -o "$${VMDK_GZ}" "${local.vmdk_gz_url}" || \
          curl -sSL -o "$${VMDK_GZ}" "https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/rhcos-aws.x86_64.vmdk.gz"
        gunzip -f "$${VMDK_GZ}" 2>/dev/null || true
        [ -f "$${VMDK}" ] || mv "$${VMDK_GZ%.gz}" "$${VMDK}" 2>/dev/null || true
      fi

      if [ ! -f "$${VMDK}" ]; then
        echo "ERROR: Could not obtain VMDK. Try setting rhcos_mirror_base to a specific version (e.g. 4.20)."
        exit 1
      fi

      echo "Uploading to s3://$${BUCKET}/$${VMDK} ..."
      aws s3 cp "$${VMDK}" "s3://$${BUCKET}/$${VMDK}" --region "$${REGION}"

      echo "Starting import-snapshot (takes ~15 min) ..."
      IMPORT_TASK=$(aws ec2 import-snapshot --region "$${REGION}" \
        --description "RHCOS-${var.ocp_version}-OpenShift" \
        --disk-container "{\"Description\":\"RHCOS\",\"Format\":\"vmdk\",\"UserBucket\":{\"S3Bucket\":\"$${BUCKET}\",\"S3Key\":\"$${VMDK}\"}}" \
        --query 'ImportTaskId' --output text)

      echo "Waiting for import task $${IMPORT_TASK} ..."
      until SNAPSHOT_ID=$(aws ec2 describe-import-snapshot-tasks --region "$${REGION}" \
        --import-task-ids "$${IMPORT_TASK}" \
        --query 'ImportSnapshotTasks[0].SnapshotTaskDetail.SnapshotId' --output text 2>/dev/null) && [ "$${SNAPSHOT_ID}" != "None" ] && [ -n "$${SNAPSHOT_ID}" ]; do
        sleep 30
        echo "  Still importing..."
      done

      echo "Creating AMI from snapshot $${SNAPSHOT_ID} ..."
      NEW_AMI=$(aws ec2 register-image --region "$${REGION}" \
        --name "$${AMI_NAME}" \
        --architecture x86_64 \
        --root-device-name "/dev/sda1" \
        --ena-support \
        --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"SnapshotId\":\"$${SNAPSHOT_ID}\",\"VolumeType\":\"gp3\"}}]" \
        --query 'ImageId' --output text)

      echo "AMI created: $${NEW_AMI}"
    EOT
    interpreter = ["bash", "-c"]
  }
}

# AMI ID after import completes (only when we ran the import)
data "aws_ami" "rhcos_imported" {
  count = length(null_resource.import_rhcos) > 0 ? 1 : 0

  most_recent = true
  owners      = [var.aws_account_id]

  filter {
    name   = "name"
    values = [local.ami_name]
  }

  depends_on = [null_resource.import_rhcos]
}
