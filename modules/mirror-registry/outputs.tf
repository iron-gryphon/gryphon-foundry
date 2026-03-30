output "mirror_registry_url" {
  description = "Mirror registry URL for install-config (use with :443 or omit for default HTTPS)"
  value       = "mirror.${var.base_domain}"
}

output "mirror_registry_ip" {
  description = "Private IP of mirror registry (for Route53 when zone exists)"
  value       = aws_instance.mirror_registry.private_ip
}

output "mirror_registry_public_ip" {
  description = "Public IP of mirror registry (for oc-mirror from outside VPC)"
  value       = aws_instance.mirror_registry.public_ip
}

output "mirror_registry_additional_trust_bundle" {
  description = "PEM of the offline CA that signs the registry certificate. Pass to gryphon-forge as mirror_registry_additional_trust_bundle for install-config additionalTrustBundle."
  value       = tls_self_signed_cert.mirror_registry_ca.cert_pem
}
