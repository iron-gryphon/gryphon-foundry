output "ingress_certificate_arn" {
  description = "ARN of the ACM certificate for OpenShift ingress (*.apps.<cluster>.<domain>)"
  value       = var.use_private_ca ? aws_acm_certificate.ingress_private[0].arn : aws_acm_certificate.ingress_public[0].arn
}
