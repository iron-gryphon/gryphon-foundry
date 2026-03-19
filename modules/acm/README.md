# ACM Module

Creates an ACM certificate for OpenShift ingress (`*.apps.<cluster>.<domain>`).

## Modes

### Public ACM (DNS validation)
- Set `use_private_ca = false`
- Requires `route53_hosted_zone_name` (zone must exist in the account)
- Certificate is validated via Route53 DNS records
- Use for public domains (e.g. sandbox.example.com)

### Private CA
- Set `use_private_ca = true`
- Creates ACM Private Certificate Authority and issues a private certificate
- No DNS validation required
- Use for internal domains (e.g. fsi.internal)

## Variables

| Name | Description |
|------|-------------|
| cluster_name | OpenShift cluster name |
| base_domain | Base domain (e.g. fsi.internal or sandbox.example.com) |
| route53_hosted_zone_name | Route53 zone name (required for public ACM) |
| use_private_ca | Use Private CA instead of public ACM |

## Outputs

| Name | Description |
|------|-------------|
| ingress_certificate_arn | ARN of the ACM certificate |
