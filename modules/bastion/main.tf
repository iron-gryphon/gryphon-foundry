# Bastion Module: Internet-accessible jump host with OCP CLI access to Vault
# Deployed in Nest (connected) VPC, reaches OCP API in Vault via VPC peering

locals {
  oc_mirror_pull_secret_shell = replace(var.oc_mirror_pull_secret_path, "~", "$HOME")
}

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
%{if var.mirror_registry_ca_pem != ""}
# Trust Foundry mirror registry offline CA (required for oc mirror to docker://mirror.<domain>/...)
mkdir -p /etc/pki/ca-trust/source/anchors
cat >/etc/pki/ca-trust/source/anchors/gryphon-mirror-registry-ca.pem <<'MIRROR_CA_EOF'
${chomp(var.mirror_registry_ca_pem)}
MIRROR_CA_EOF
chmod 644 /etc/pki/ca-trust/source/anchors/gryphon-mirror-registry-ca.pem
update-ca-trust extract
%{endif}
# OpenShift CLI + oc-mirror (same release channel as ocp_version via stable-<x.y>)
OCP_RELEASE="${var.oc_release}"
curl -fsSL "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$${OCP_RELEASE}/openshift-client-linux.tar.gz" | tar xz -C /usr/local/bin
chmod +x /usr/local/bin/oc /usr/local/bin/kubectl
curl -fsSL "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$${OCP_RELEASE}/oc-mirror.tar.gz" | tar xz -C /usr/local/bin
chmod +x /usr/local/bin/oc-mirror
mkdir -p /home/ec2-user/.openshift
chown ec2-user:ec2-user /home/ec2-user/.openshift
cat >/etc/profile.d/gryphon-oc-mirror.sh <<'EOS'
# gryphon-foundry: pull secret for oc mirror (copy JSON from cloud.redhat.com)
export GRYPHON_OCP_PULL_SECRET="${local.oc_mirror_pull_secret_shell}"
gryphon_oc_mirror() {
  oc mirror --registry-config "$${GRYPHON_OCP_PULL_SECRET}" "$$@"
}
EOS
echo "Bastion ready: oc, oc mirror plugin, oc-mirror binary. Configure pull secret at ${local.oc_mirror_pull_secret_shell} then use: gryphon_oc_mirror <args>"
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
