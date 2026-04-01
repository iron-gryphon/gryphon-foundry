#!/usr/bin/env bash
# Post-apply: confirm the OCP internal/private Route53 zone is associated with the Vault VPC
# so AmazonProvidedDNS (VPC+2) resolves api-int for RHCOS workers (avoids Ignition NXDOMAIN).
#
# Usage:
#   cd <repo-root> && ./scripts/validate-vault-ocp-dns.sh
#   ./scripts/validate-vault-ocp-dns.sh /path/to/foundry_output.json
#
# Requires: aws CLI, jq, terraform (when using default JSON from `terraform output -json`).
# AWS credentials must be able to call route53:ListHostedZonesByVPC.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
JSON_FILE="${1:-}"

err() {
  echo "Error: $*" >&2
  exit 1
}

if ! command -v jq &>/dev/null; then
  err "jq not found"
fi
if ! command -v aws &>/dev/null; then
  err "aws CLI not found"
fi

if [[ -z "$JSON_FILE" ]]; then
  if ! command -v terraform &>/dev/null; then
    err "terraform not found; pass foundry_output.json as first argument"
  fi
  cd "$ROOT_DIR"
  JSON_FILE="$(mktemp)"
  trap 'rm -f "$JSON_FILE"' EXIT
  terraform output -json >"$JSON_FILE"
fi

if [[ ! -f "$JSON_FILE" ]]; then
  err "file not found: $JSON_FILE"
fi

REGION="$(jq -r '.region.value // empty' "$JSON_FILE")"
VAULT_VPC="$(jq -r '.vault_vpc_id.value // empty' "$JSON_FILE")"
ZONE_ID="$(jq -r '.internal_hosted_zone_id.value // empty' "$JSON_FILE")"
API_INT="$(jq -r '.ocp_api_int_fqdn.value // empty' "$JSON_FILE")"
VAULT_DNS="$(jq -r '.vault_vpc_amazon_provided_dns.value // empty' "$JSON_FILE")"

[[ -n "$REGION" ]] || err "missing region.value in JSON"
[[ -n "$VAULT_VPC" ]] || err "missing vault_vpc_id.value in JSON"

if [[ -z "$ZONE_ID" || "$ZONE_ID" == "null" ]]; then
  echo "Skip: internal_hosted_zone_id is unset (no OCP base domain / zone configured)."
  exit 0
fi

# Normalize zone id (terraform outputs bare id; API may return /hostedzone/ prefix)
ZONE_SUFFIX="${ZONE_ID#/hostedzone/}"

echo "==> Checking Route53: hosted zone $ZONE_ID associated with Vault VPC $VAULT_VPC ($REGION) ..."
LIST="$(aws route53 list-hosted-zones-by-vpc --vpc-id "$VAULT_VPC" --vpc-region "$REGION" --output json)"
if ! echo "$LIST" | jq -e --arg zid "$ZONE_SUFFIX" '
  .HostedZoneSummaries // []
  | map(.HostedZoneId | sub("^/hostedzone/"; ""))
  | index($zid) != null
' >/dev/null; then
  err "hosted zone $ZONE_ID is NOT associated with Vault VPC $VAULT_VPC. Workers will NXDOMAIN api-int. Run terraform apply (aws_route53_zone_association / private zone) or associate the zone manually."
fi

echo "OK: private zone is associated with Vault VPC."

if [[ -n "$API_INT" && "$API_INT" != "null" && -n "$VAULT_DNS" && "$VAULT_DNS" != "null" ]]; then
  echo ""
  echo "Optional name resolution (after Forge creates api-int record):"
  echo "  dig +short $API_INT @$VAULT_DNS"
  echo "(Run from any host in a Vault subnet using Amazon DNS, or from a test instance.)"
fi
