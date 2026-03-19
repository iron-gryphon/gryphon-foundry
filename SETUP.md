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
export AWS_REGION="us-east-2"                    # Or set via terraform.tfvars
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
# Default region name: us-east-2
```

Terraform uses the same credential chain automatically.

### Option 3: Terraform Variables (TF_VAR_*)

For non-sensitive values like region, you can use:

```bash
export TF_VAR_aws_region="us-east-2"
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

   - `aws_region` – Target AWS region (e.g., `us-east-2`, `us-gov-west-1`)
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

---

## Slack Notifications (Optional)

The `.github/workflows/slack-notify.yml` workflow triggers a **Slack Workflow** when:

- **Main branch updates** – New commits are pushed or merged to `main` or `master`
- **Dependabot PRs** – A new dependency update PR is opened

Uses Slack Workflow Builder (webhook trigger) instead of an Incoming Webhook app. Requires a [Slack paid plan](https://slack.com/pricing).

### Setup

1. **Create a Slack Workflow with a webhook trigger**
   - In Slack: **Settings & administration** → **Workflow Builder** → **Create** → **From scratch**
   - Add trigger: **Webhook** → **Add variable** for each payload field (see below)
   - Add step: **Send a message to a channel** – use the variables to build your message
   - Copy the webhook URL (format: `https://hooks.slack.com/triggers/T.../.../...`)

2. **Add the secret to GitHub**
   - Repo → **Settings** → **Secrets and variables** → **Actions**
   - New repository secret: `SLACK_WEBHOOK_URL` = your workflow webhook URL

### Payload variables (add these to your webhook trigger)

**Main branch** (`event_type: main_update`):

| Variable       | Description                    |
|----------------|--------------------------------|
| `event_type`   | `main_update`                  |
| `repo`         | Repository (e.g. `owner/repo`) |
| `branch`       | Branch name                    |
| `commit_sha`   | Short commit SHA (7 chars)     |
| `commit_message` | Commit message (truncated)  |
| `author`       | Commit author                  |
| `compare_url`  | URL to view changes            |

**Dependabot PR** (`event_type: dependabot_pr`):

| Variable       | Description                    |
|----------------|--------------------------------|
| `event_type`   | `dependabot_pr`                |
| `pr_number`    | PR number                      |
| `pr_title`     | PR title                       |
| `pr_url`       | URL to the PR                  |
| `pr_body`      | PR body (truncated)            |

In your workflow, add a **Send a message** step and reference variables like `{{event_type}}`, `{{repo}}`, etc. Use `{{compare_url}}` or `{{pr_url}}` as links.

### Example message templates

**Main branch update** – Use in your "Send a message" step when `event_type` is `main_update`:

```
🦅 *Main Branch Updated*

*Repository:* {{repo}}
*Branch:* {{branch}}
*Commit:* <{{compare_url}}|{{commit_sha}}>
*Author:* {{author}}

*Message:* {{commit_message}}

<{{compare_url}}|View changes>
```

**Dependabot PR** – Use in your "Send a message" step when `event_type` is `dependabot_pr`:

```
📦 *Dependabot Dependency Update*

*PR #{{pr_number}}:* {{pr_title}}

{{pr_body}}

<{{pr_url}}|View PR>
```

> **Tip:** If you use a single workflow for both event types, add a **Branch** step before "Send a message" and route by `event_type` (e.g., `main_update` → main message template, `dependabot_pr` → Dependabot message template).

If `SLACK_WEBHOOK_URL` is not set, the notification jobs are skipped (no failure). To fully disable notifications, remove or disable the `slack-notify.yml` workflow.
