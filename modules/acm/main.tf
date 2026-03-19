# -----------------------------------------------------------------------------
# ACM Module: Ingress certificates for OpenShift UPI
# Domain: *.apps.<cluster_name>.<base_domain> and apps.<cluster_name>.<base_domain>
# -----------------------------------------------------------------------------

locals {
  ingress_domain = "${var.cluster_name}.${var.base_domain}"
  wildcard_fqdn  = "*.apps.${local.ingress_domain}"
  apex_fqdn      = "apps.${local.ingress_domain}"
}

# -----------------------------------------------------------------------------
# Option A: Private CA (for internal domains like fsi.internal)
# -----------------------------------------------------------------------------
resource "aws_acmpca_certificate_authority" "ingress" {
  count = var.use_private_ca ? 1 : 0

  type = "ROOT"

  certificate_authority_configuration {
    key_algorithm     = "RSA_2048"
    signing_algorithm = "SHA256WITHRSA"

    subject {
      common_name         = "gryphon-ingress-${var.environment}"
      organization        = "Iron Gryphon"
      organizational_unit = "FSI"
      country             = "US"
    }
  }

  permanent_deletion_time_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.environment}-ingress-ca"
  })
}

resource "aws_acmpca_certificate_authority_certificate" "ingress" {
  count = var.use_private_ca ? 1 : 0

  certificate_authority_arn = aws_acmpca_certificate_authority.ingress[0].arn

  certificate       = aws_acmpca_certificate.ingress_root[0].certificate
  certificate_chain = aws_acmpca_certificate.ingress_root[0].certificate_chain
}

resource "aws_acmpca_certificate" "ingress_root" {
  count = var.use_private_ca ? 1 : 0

  certificate_authority_arn   = aws_acmpca_certificate_authority.ingress[0].arn
  certificate_signing_request = aws_acmpca_certificate_authority.ingress[0].certificate_signing_request
  signing_algorithm           = "SHA256WITHRSA"

  validity {
    type  = "YEARS"
    value = 10
  }

  template_arn = "arn:aws:acm-pca:::template/RootCACertificate/V1"
}

resource "aws_acmpca_permission" "acm_issue" {
  count = var.use_private_ca ? 1 : 0

  certificate_authority_arn = aws_acmpca_certificate_authority.ingress[0].arn
  actions                   = ["IssueCertificate", "GetCertificate", "ListPermissions"]
  principal                 = "acm.amazonaws.com"
}

resource "aws_acm_certificate" "ingress_private" {
  count = var.use_private_ca ? 1 : 0

  domain_name               = local.wildcard_fqdn
  subject_alternative_names = [local.apex_fqdn]
  certificate_authority_arn = aws_acmpca_certificate_authority.ingress[0].arn
  # Private CA - no validation_method needed

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-ingress-cert"
  })
}

# -----------------------------------------------------------------------------
# Option B: Public ACM (DNS validation) - for public Route53 zones
# -----------------------------------------------------------------------------
data "aws_route53_zone" "ingress" {
  count = var.use_private_ca ? 0 : 1

  name = var.route53_hosted_zone_name
}

resource "aws_acm_certificate" "ingress_public" {
  count = var.use_private_ca ? 0 : 1

  domain_name               = local.wildcard_fqdn
  subject_alternative_names = [local.apex_fqdn]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-ingress-cert"
  })
}

resource "aws_route53_record" "ingress_validation" {
  for_each = var.use_private_ca ? {} : {
    for dvo in aws_acm_certificate.ingress_public[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.ingress[0].id
}

resource "aws_acm_certificate_validation" "ingress" {
  count = var.use_private_ca ? 0 : 1

  certificate_arn         = aws_acm_certificate.ingress_public[0].arn
  validation_record_fqdns = [for record in aws_route53_record.ingress_validation : record.fqdn]
}
