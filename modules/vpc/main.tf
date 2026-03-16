# VPC Module: Dual-VPC Architecture (Nest + Vault)
# The Nest: Connected VPC for oc-mirror, datasets, Terraform providers
# The Vault: Isolated VPC with no IGW/NAT - air-gapped for OCP/RHOAI

# -----------------------------------------------------------------------------
# VPC-A: The Nest (Connected)
# -----------------------------------------------------------------------------
resource "aws_vpc" "nest" {
  cidr_block           = var.nest_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.environment}-nest-vpc"
    Role = "nest"
  })
}

resource "aws_internet_gateway" "nest" {
  vpc_id = aws_vpc.nest.id

  tags = merge(var.tags, {
    Name = "${var.environment}-nest-igw"
  })
}

resource "aws_subnet" "nest_public" {
  count = length(var.nest_public_subnet_cidrs)

  vpc_id                  = aws_vpc.nest.id
  cidr_block              = var.nest_public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.environment}-nest-public-${count.index + 1}"
    Role = "nest-public"
  })
}

resource "aws_route_table" "nest_public" {
  vpc_id = aws_vpc.nest.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nest.id
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-nest-public-rt"
  })
}

resource "aws_route_table_association" "nest_public" {
  count = length(aws_subnet.nest_public)

  subnet_id      = aws_subnet.nest_public[count.index].id
  route_table_id = aws_route_table.nest_public.id
}

# -----------------------------------------------------------------------------
# VPC-B: The Vault (Isolated - No IGW, No NAT)
# -----------------------------------------------------------------------------
resource "aws_vpc" "vault" {
  cidr_block           = var.vault_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.environment}-vault-vpc"
    Role = "vault"
  })
}

resource "aws_subnet" "vault_private" {
  count = length(var.vault_private_subnet_cidrs)

  vpc_id            = aws_vpc.vault.id
  cidr_block        = var.vault_private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.environment}-vault-private-${count.index + 1}"
    Role = "vault-private"
  })
}

resource "aws_route_table" "vault_private" {
  vpc_id = aws_vpc.vault.id

  # No default route to internet - maintains air-gap integrity

  tags = merge(var.tags, {
    Name = "${var.environment}-vault-private-rt"
  })
}

resource "aws_route_table_association" "vault_private" {
  count = length(aws_subnet.vault_private)

  subnet_id      = aws_subnet.vault_private[count.index].id
  route_table_id = aws_route_table.vault_private.id
}

# -----------------------------------------------------------------------------
# VPC Peering: Nest <-> Vault (for bastion access to OCP)
# -----------------------------------------------------------------------------
resource "aws_vpc_peering_connection" "nest_to_vault" {
  vpc_id      = aws_vpc.nest.id
  peer_vpc_id = aws_vpc.vault.id
  auto_accept = true

  tags = merge(var.tags, {
    Name = "${var.environment}-nest-vault-peering"
  })
}

# Route: Nest public -> Vault (via peering)
resource "aws_route" "nest_to_vault" {
  route_table_id            = aws_route_table.nest_public.id
  destination_cidr_block    = var.vault_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.nest_to_vault.id
}

# Route: Vault -> Nest (via peering, for return traffic)
resource "aws_route" "vault_to_nest" {
  route_table_id            = aws_route_table.vault_private.id
  destination_cidr_block    = var.nest_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.nest_to_vault.id
}
