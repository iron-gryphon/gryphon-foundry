# Security Module: IAM, KMS, and Security Groups
# Provides encryption keys and network security for Nest and Vault

# -----------------------------------------------------------------------------
# KMS Key for EBS and S3 encryption (Sneakernet bridge)
# -----------------------------------------------------------------------------
resource "aws_kms_key" "sneakernet" {
  description             = "KMS key for Sneakernet EBS snapshots and S3 objects"
  deletion_window_in_days = var.kms_deletion_window_days

  tags = merge(var.tags, {
    Name = "${var.environment}-sneakernet-kms"
  })
}

resource "aws_kms_alias" "sneakernet" {
  name          = "alias/${var.environment}-sneakernet"
  target_key_id = aws_kms_key.sneakernet.key_id
}

# -----------------------------------------------------------------------------
# Security Group: Nest (connected) - Allow outbound to internet
# -----------------------------------------------------------------------------
resource "aws_security_group" "nest" {
  name        = "${var.environment}-nest-sg"
  description = "Security group for Nest VPC - oc-mirror, image pull, Terraform providers"
  vpc_id      = var.nest_vpc_id

  # Outbound: Allow all for oc-mirror, registry pulls, Terraform provider downloads
  egress {
    description = "Allow all outbound (required for oc-mirror and registry access)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-nest-sg"
  })
}

# -----------------------------------------------------------------------------
# Security Group: Vault (isolated) - Internal only, no egress to internet
# -----------------------------------------------------------------------------
resource "aws_security_group" "vault" {
  name        = "${var.environment}-vault-sg"
  description = "Security group for Vault VPC - OCP/RHOAI, internal traffic only"
  vpc_id      = var.vault_vpc_id

  # Ingress: Allow internal VPC traffic
  ingress {
    description = "Allow internal VPC traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vault_vpc_cidr]
  }

  ingress {
    description = "Allow internal VPC traffic (UDP)"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [var.vault_vpc_cidr]
  }

  # Egress: Only within Vault VPC - no internet
  egress {
    description = "Allow outbound within Vault VPC only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vault_vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-vault-sg"
  })
}

# -----------------------------------------------------------------------------
# Security Group: Vault API/Ingress (for OCP bootstrap and API)
# -----------------------------------------------------------------------------
resource "aws_security_group" "vault_api" {
  name        = "${var.environment}-vault-api-sg"
  description = "Vault OCP API, MCS, ingress (80/443), and bootstrap etcd (2379/2380) from Vault VPC"
  vpc_id      = var.vault_vpc_id

  # Temporary bootstrap etcd: control-plane nodes must reach the bootstrap private IP on 2379 (client)
  # and 2380 (peer) before membership migrates. Not opened from Nest — etcd stays Vault-internal.
  ingress {
    description = "Bootstrap etcd client and peer from Vault VPC (TCP 2379-2380)"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.vault_vpc_cidr]
  }

  ingress {
    description = "HTTPS (OCP API) from Vault"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vault_vpc_cidr]
  }

  ingress {
    description = "HTTPS (OCP API) from bastion in Nest"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.nest_vpc_cidr]
  }

  # Machine Config Server (same internal hostname as API: https://api-int:22623/... on masters)
  ingress {
    description = "MCS (Machine Config Server) from Vault"
    from_port   = 22623
    to_port     = 22623
    protocol    = "tcp"
    cidr_blocks = [var.vault_vpc_cidr]
  }

  ingress {
    description = "MCS from bastion in Nest"
    from_port   = 22623
    to_port     = 22623
    protocol    = "tcp"
    cidr_blocks = [var.nest_vpc_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vault_vpc_cidr]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vault_vpc_cidr]
  }

  ingress {
    description = "HTTPS (OCP web console) from bastion in Nest"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.nest_vpc_cidr]
  }

  egress {
    description = "Allow outbound within Vault VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vault_vpc_cidr]
  }

  egress {
    description = "Allow outbound to Nest (bastion return traffic)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.nest_vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-vault-api-sg"
  })
}

# -----------------------------------------------------------------------------
# Security Group: Interface VPC endpoints (IAM, STS, EC2, ELB, …) in Vault
# ENIs for these endpoints receive traffic from OCP nodes on 443; destinations
# stay inside the VPC CIDR (no IGW/NAT required).
# -----------------------------------------------------------------------------
resource "aws_security_group" "vault_interface_endpoints" {
  name        = "${var.environment}-vault-interface-endpoints-sg"
  description = "HTTPS from Vault VPC to AWS API interface VPC endpoints (air-gapped OCP)"
  vpc_id      = var.vault_vpc_id

  ingress {
    description = "HTTPS from Vault VPC workloads to AWS API endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vault_vpc_cidr]
  }

  egress {
    description = "Allow return traffic (required for endpoint ENIs)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-vault-interface-endpoints-sg"
  })
}
