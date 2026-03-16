output "nest_staging_bucket_name" {
  description = "Name of the Nest staging S3 bucket"
  value       = aws_s3_bucket.nest_staging.id
}

output "nest_staging_bucket_arn" {
  description = "ARN of the Nest staging S3 bucket"
  value       = aws_s3_bucket.nest_staging.arn
}

output "vault_receiving_bucket_name" {
  description = "Name of the Vault receiving S3 bucket"
  value       = aws_s3_bucket.vault_receiving.id
}

output "vault_receiving_bucket_arn" {
  description = "ARN of the Vault receiving S3 bucket"
  value       = aws_s3_bucket.vault_receiving.arn
}

output "vault_s3_endpoint_id" {
  description = "ID of the S3 VPC gateway endpoint in Vault"
  value       = aws_vpc_endpoint.vault_s3.id
}

output "ebs_snapshot_share_policy_arn" {
  description = "ARN of IAM policy for EBS snapshot sharing"
  value       = aws_iam_policy.ebs_snapshot_share.arn
}
