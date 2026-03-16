# Bastion Module: Internet-accessible jump host with OCP CLI access to Vault
# Deployed in Nest (connected) VPC, reaches OCP API in Vault via VPC peering

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# -----------------------------------------------------------------------------
# Security Group: Bastion
# -----------------------------------------------------------------------------
resource "aws_security_group" "bastion" {
  name        = "${var.environment}-bastion-sg"
  description = "Bastion host - SSH from internet, outbound to Vault for OCP API"
  vpc_id      = var.nest_vpc_id

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  egress {
    description = "Allow all outbound (internet for oc-cli install, Vault for OCP API)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-bastion-sg"
  })
}

# -----------------------------------------------------------------------------
# Bastion EC2 Instance
# -----------------------------------------------------------------------------
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.nest_public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  user_data = <<-EOT
#!/bin/bash
set -e
# Install OpenShift CLI (oc) for OCP access from bastion
OC_VERSION="${var.oc_cli_version}"
curl -sL "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$${OC_VERSION}/openshift-client-linux.tar.gz" | tar xz -C /usr/local/bin
chmod +x /usr/local/bin/oc /usr/local/bin/kubectl
echo "Bastion ready. Use 'oc login' with OCP API URL (e.g. https://api.<cluster>.<domain>:6443) after cluster is deployed."
EOT

  tags = merge(var.tags, {
    Name = "${var.environment}-bastion"
    Role = "bastion"
  })
}

# -----------------------------------------------------------------------------
# Route53: Bastion A record (when hosted zone is provided)
# -----------------------------------------------------------------------------
data "aws_route53_zone" "sandbox" {
  count = var.route53_hosted_zone_name != "" ? 1 : 0

  name = var.route53_hosted_zone_name
}

resource "aws_route53_record" "bastion" {
  count = var.route53_hosted_zone_name != "" ? 1 : 0

  zone_id = data.aws_route53_zone.sandbox[0].zone_id
  name    = "bastion"
  type    = "A"
  ttl     = 300
  records = [aws_instance.bastion.public_ip]
}
