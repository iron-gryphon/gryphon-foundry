#!/usr/bin/env bash
# Validate terraform output -json shape expected by gryphon-forge (preflight / deploy_cluster).
# Usage: ./scripts/check-foundry-json-for-forge.sh [foundry_output.json]
# Requires: jq

set -euo pipefail

JSON_FILE="${1:-foundry_output.json}"

if ! command -v jq &>/dev/null; then
  echo "Error: jq not found. Install jq to use this script."
  exit 1
fi

if [[ ! -f "$JSON_FILE" ]]; then
  echo "Error: file not found: $JSON_FILE"
  echo "Generate with: terraform output -json > foundry_output.json"
  exit 1
fi

err() {
  echo "Error: $*"
  exit 1
}

# Terraform output format: each key is an object with .value
jq -e '.vault_vpc_id.value != null and (.vault_vpc_id.value | tostring | length) > 0' "$JSON_FILE" >/dev/null || err "missing vault_vpc_id.value"
jq -e '((.vault_private_subnet_ids.value // .ocp_upi_subnet_ids.value) | type == "array") and ((.vault_private_subnet_ids.value // .ocp_upi_subnet_ids.value) | length >= 3)' "$JSON_FILE" >/dev/null \
  || err "need vault_private_subnet_ids.value or ocp_upi_subnet_ids.value with at least 3 subnets"
# internal_hosted_zone_id is null in outputs.tf when neither ocp_base_domain nor route53_hosted_zone_name is set; only require zone ID when a base domain is present.
jq -e '
  def base_domain: (.ocp_base_domain.value // "") | tostring;
  if (base_domain | length) > 0 then
    (.internal_hosted_zone_id.value != null and ((.internal_hosted_zone_id.value | tostring) | length) > 0)
    and (.ocp_cluster_name.value != null and ((.ocp_cluster_name.value | tostring) | length) > 0)
    and (.ocp_api_int_fqdn.value != null and ((.ocp_api_int_fqdn.value | tostring) | length) > 0)
    and (.vault_vpc_amazon_provided_dns.value != null and ((.vault_vpc_amazon_provided_dns.value | tostring) | length) > 0)
  else true end
' "$JSON_FILE" >/dev/null \
  || err "missing internal_hosted_zone_id, ocp_cluster_name, ocp_api_int_fqdn, or vault_vpc_amazon_provided_dns (required when ocp_base_domain is set)"
jq -e '.region.value != null and (.region.value | tostring | length) > 0' "$JSON_FILE" >/dev/null || err "missing region.value"

if jq -e '(.bastion_public_ip.value // .bastion_public_ip // "") | tostring | length > 0' "$JSON_FILE" >/dev/null; then
  jq -e '.nest_vpc_cidr.value != null and (.nest_vpc_cidr.value | tostring | length) > 0' "$JSON_FILE" >/dev/null \
    || err "bastion is present but nest_vpc_cidr.value is missing (Forge needs Nest CIDR for bootstrap SG 6443/22623)"
fi

echo "OK: $JSON_FILE has required keys for gryphon-forge."
