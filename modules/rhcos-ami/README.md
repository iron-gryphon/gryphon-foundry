# RHCOS AMI Import Module

Imports Red Hat CoreOS (RHCOS) from [mirror.openshift.com](https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/) into your AWS account as an AMI. Use when your account cannot access Red Hat's AMIs directly (AuthFailure, empty image list).

## Requirements

- **curl** and **aws CLI** installed (for the import script)
- **Internet access** to mirror.openshift.com (for initial download)
- **~15–20 minutes** for the first `terraform apply` (download + S3 upload + EC2 import)

## Resources Created

- S3 bucket for VMDK upload
- IAM role `vmimport` (required by AWS VM Import/Export)
- RHCOS AMI (after import completes)

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ocp_version` | OpenShift version (e.g. 4.20) | 4.20 |
| `import_rhcos_ami` | Run the import (set false if AMI already exists) | true |
| `rhcos_mirror_base` | Mirror path (e.g. `4.20/latest` or `latest`) | `ocp_version/latest` |

## Outputs

- `rhcos_ami_id` — AMI ID to pass to gryphon-forge
- `rhcos_import_bucket_name` — S3 bucket (for manual import if needed)

## ENA Support

The AMI is registered with `--ena-support` so it works with modern instance types (m6i, m5, etc.) that require Enhanced Networking. If you have an **existing AMI** created before this was added and see `InvalidParameterCombination: Enhanced networking with the Elastic Network Adapter (ENA) is required`, you must re-import the AMI:

1. Deregister the old AMI: `aws ec2 deregister-image --image-id ami-xxxxxxxxx`
2. Taint the import so Terraform re-runs it: `terraform taint 'module.rhcos_ami[0].null_resource.import_rhcos[0]'`
3. Run `terraform apply` (the import will create a new AMI with ENA)
4. Update gryphon-forge's `foundry_output.json` with the new `rhcos_ami_id`

## Existing vmimport Role

If the `vmimport` IAM role already exists in your account (e.g. from another project), import it before apply:

```bash
terraform import 'module.rhcos_ami[0].aws_iam_role.vmimport' vmimport
```

Then run `terraform apply` — Terraform will update the role policy to include this module's S3 bucket.
