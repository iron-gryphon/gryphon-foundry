#!/usr/bin/env bash
# validate.sh - Run Terraform format check and validation.
# Agents should run this after making changes. See AGENTS.md.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v terraform &>/dev/null; then
  echo "Error: terraform not found. Install Terraform 1.x+ and retry."
  exit 1
fi

echo "==> Checking Terraform formatting..."
terraform fmt -recursive -check -diff

echo "==> Initializing Terraform (backend=false)..."
terraform init -backend=false

echo "==> Validating Terraform configuration..."
terraform validate

echo "==> Validation passed."
