output "bastion_security_group_id" {
  description = "Security group ID of the bastion host (for bootstrap/master SG rules allowing API/MCS from bastion)"
  value       = aws_security_group.bastion.id
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_public_dns" {
  description = "Public DNS name of the bastion host"
  value       = aws_instance.bastion.public_dns
}

output "bastion_ssh_command" {
  description = "SSH command to connect to the bastion"
  value       = "ssh -i <your-key.pem> ec2-user@${aws_instance.bastion.public_ip}"
}

output "bastion_hostname" {
  description = "Bastion hostname (bastion.<zone>) when Route53 hosted zone is configured, null otherwise"
  value       = var.route53_hosted_zone_name != "" ? "bastion.${trimsuffix(var.route53_hosted_zone_name, ".")}" : null
}
