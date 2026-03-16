# gryphon-foundry Setup Guide

This guide covers AWS credential configuration and optional custom endpoint setup for the target environment.

---

## AWS Credentials

**Never put AWS credentials in `.tf` files or `terraform.tfvars`.** Use one of these methods:

### Option 1: Environment Variables (Recommended for CI/CD)

```bash
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_SESSION_TOKEN="your-session-token"   # Optional, for temporary credentials
export AWS_REGION="us-east-1"                    # Or set via terraform.tfvars
```

Then run Terraform:

```bash
terraform init
terraform plan -var-file=terraform.tfvars -out=forge.plan
terraform apply "forge.plan"
```

### Option 2: AWS CLI Configuration (~/.aws/credentials)

Configure the AWS CLI:

```bash
aws configure
# AWS Access Key ID: your-access-key-id
# AWS Secret Access Key: your-secret-access-key
# Default region name: us-east-1
```

Terraform uses the same credential chain automatically.

### Option 3: Terraform Variables (TF_VAR_*)

For non-sensitive values like region, you can use:

```bash
export TF_VAR_aws_region="us-east-1"
export TF_VAR_environment="sandbox"
# ... other TF_VAR_* as needed
```

**Do not use TF_VAR for credentials.** The AWS provider reads credentials from `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `~/.aws/credentials` only.

---

## terraform.tfvars Configuration

1. Copy the example file:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your environment values:

   - `aws_region` – Target AWS region (e.g., `us-east-1`, `us-gov-west-1`)
   - `availability_zones` – AZs for your region
   - `nest_vpc_cidr` / `vault_vpc_cidr` – Ensure no overlap with existing networks
   - `nest_public_subnet_cidrs` / `vault_private_subnet_cidrs` – One CIDR per AZ

3. Run Terraform:

   ```bash
   terraform init
   terraform plan -var-file=terraform.tfvars -out=forge.plan
   terraform apply "forge.plan"
   ```

---

## Custom AWS Endpoints (GovCloud, China, PrivateLink)

For AWS GovCloud (US), AWS China, or custom endpoints (e.g., VPC endpoints for Terraform), add an override file.

Create `provider_override.tf` (add to `.gitignore` if it contains environment-specific paths):

```hcl
# provider_override.tf - Custom endpoints (example: GovCloud)
# This file overrides the default provider in main.tf

provider "aws" {
  region = var.aws_region

  endpoints {
    ec2            = "https://ec2.us-gov-west-1.amazonaws.com"
    s3             = "https://s3.us-gov-west-1.amazonaws.com"
    kms            = "https://kms.us-gov-west-1.amazonaws.com"
    sts            = "https://sts.us-gov-west-1.amazonaws.com"
    # Add other services as needed
  }
}
```

For **AWS China**, use endpoints like `https://ec2.cn-north-1.amazonaws.com.cn`.

---

## Required IAM Permissions

Your AWS credentials must have permissions for:

- **EC2**: VPC, subnets, route tables, security groups, internet gateways
- **S3**: Bucket creation, versioning, encryption
- **KMS**: Key creation and alias
- **IAM**: Policy creation (for EBS snapshot sharing)
- **Route53** (when `route53_hosted_zone_name` is set): GetHostedZone, ChangeResourceRecordSets for the sandbox hosted zone

A minimal policy would include: `ec2:*`, `s3:*`, `kms:*`, `iam:CreatePolicy`, `iam:AttachUserPolicy`, and `route53:GetHostedZone`, `route53:ChangeResourceRecordSets` (or equivalent for the resources created by this project).

---

## Validation

After making changes, run:

```bash
./scripts/validate.sh
```

This runs `terraform fmt`, `terraform init -backend=false`, and `terraform validate`.
