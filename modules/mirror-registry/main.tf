# -----------------------------------------------------------------------------
# Mirror Registry - Container registry in Nest for disconnected OCP
# Vault (air-gapped) pulls images from this registry via VPC peering.
# Run oc-mirror from bastion to populate before install.
# -----------------------------------------------------------------------------

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
# Security Group: Mirror registry - HTTPS from Vault, SSH from allowed CIDRs
# -----------------------------------------------------------------------------
resource "aws_security_group" "mirror_registry" {
  name        = "${var.environment}-mirror-registry-sg"
  description = "Mirror registry - HTTPS from Vault (OCP nodes), SSH for admin"
  vpc_id      = var.nest_vpc_id

  ingress {
    description = "HTTPS from Vault (OCP bootstrap/masters/workers pull images)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vault_vpc_cidr]
  }

  ingress {
    description = "HTTPS from Nest (oc-mirror push from bastion)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.nest_vpc_cidr]
  }

  ingress {
    description = "SSH for admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  egress {
    description = "Allow all outbound (oc-mirror pulls from Red Hat)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-mirror-registry-sg"
  })
}

# -----------------------------------------------------------------------------
# EC2 Instance - Registry host (user installs mirror registry or registry:2)
# -----------------------------------------------------------------------------
resource "aws_instance" "mirror_registry" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.nest_public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.mirror_registry.id]
  associate_public_ip_address = true

  user_data = <<-EOT
#!/bin/bash
set -e
# Install Docker and run registry (HTTPS with self-signed cert)
# User can replace with mirror registry for Red Hat OpenShift
yum install -y docker
systemctl enable docker
systemctl start docker

# Create certs dir and self-signed cert for registry
mkdir -p /opt/registry/certs
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
  -subj "/CN=mirror.${var.base_domain}" \
  -keyout /opt/registry/certs/domain.key \
  -out /opt/registry/certs/domain.crt 2>/dev/null

# Create auth dir for registry
mkdir -p /opt/registry/auth
mkdir -p /opt/registry/data

# Run registry with HTTPS on port 443
docker run -d --restart=always -p 443:443 \
  -v /opt/registry/certs:/certs:ro \
  -v /opt/registry/data:/var/lib/registry \
  -e REGISTRY_HTTP_ADDR=:443 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  -e REGISTRY_STORAGE_DELETE_ENABLED=true \
  --name registry registry:2

echo "Mirror registry ready. Run oc-mirror from bastion to populate."
EOT

  tags = merge(var.tags, {
    Name = "${var.environment}-mirror-registry"
    Role = "mirror-registry"
  })
}

# -----------------------------------------------------------------------------
# Route53: mirror.<base_domain> -> registry private IP (when zone provided)
# -----------------------------------------------------------------------------
resource "aws_route53_record" "mirror_registry" {
  count = var.create_route53_record ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = "mirror.${var.base_domain}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.mirror_registry.private_ip]
}
