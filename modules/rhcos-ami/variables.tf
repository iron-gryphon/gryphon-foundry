# -----------------------------------------------------------------------------
# RHCOS AMI Import Module (Import from public mirror)
# Creates S3 bucket, VM Import role, and imports RHCOS VMDK to create AMI
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the deployment"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "ocp_version" {
  description = "OpenShift/RHCOS version (e.g., 4.20, 4.21). Used for RHCOS mirror path and AMI naming."
  type        = string
  default     = "4.20"
}

variable "rhcos_mirror_base" {
  description = "RHCOS mirror path: 'latest' for top-level or '4.20/latest' for version-specific. Defaults to ocp_version/latest."
  type        = string
  default     = ""
}

variable "import_rhcos_ami" {
  description = "When true, download RHCOS VMDK from mirror and import as AMI. Requires curl, aws CLI, and ~15 min. Set false to skip import (e.g., AMI already exists)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
