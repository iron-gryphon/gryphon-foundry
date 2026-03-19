output "rhcos_ami_id" {
  description = "RHCOS AMI ID (imported from mirror.openshift.com). Use in gryphon-forge as rhcos_ami_id."
  value       = var.import_rhcos_ami && length(data.aws_ami.rhcos_imported) > 0 ? data.aws_ami.rhcos_imported[0].id : null
}

output "rhcos_import_bucket_name" {
  description = "S3 bucket used for RHCOS VMDK import (for manual import if needed)"
  value       = aws_s3_bucket.rhcos_import.id
}
