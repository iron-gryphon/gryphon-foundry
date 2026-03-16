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
