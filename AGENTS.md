# Agent Instructions for gryphon-foundry

Guidance for AI agents working on this Terraform project. See also [CONTRIBUTING.md](CONTRIBUTING.md) and [README.md](README.md).

---

## 🔒 Security: No Secrets in Code

**CRITICAL: Never generate, hardcode, or suggest placing secrets in source code.**

- **Do NOT** hardcode API keys, passwords, tokens, pull secrets, or any credentials in `.tf` files, `.tfvars`, or committed configs.
- **Do NOT** suggest `default` values for sensitive variables (e.g., `aws_access_key`, `pull_secret`, `private_key`).
- **DO** use environment variables, external secret managers, or local-only config:
  - `TF_VAR_*` for Terraform variables (e.g., `TF_VAR_aws_region`)
  - `~/.aws/credentials` or `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` for AWS
  - `*.tfvars` or `*.tfvars.json` in `.gitignore` for local overrides (already ignored)
  - References to HashiCorp Vault, AWS Secrets Manager, or similar in docs
- **DO** document required variables in `variables.tf` with `sensitive = true` and no `default`.
- **DO** add `.env.example` or `terraform.tfvars.example` with placeholder values (e.g., `your-aws-region`) and instructions to copy and fill locally.

---

## 🛠️ After Making Changes: Test and Lint

Agents **must** run validation after editing Terraform or related config. Use the project scripts:

```bash
# From project root
./scripts/validate.sh
```

Or run these steps manually:

| Step | Command | Purpose |
|------|---------|---------|
| Format | `terraform fmt -recursive -check -diff` | Enforce consistent formatting |
| Validate | `terraform init -backend=false && terraform validate` | Syntax and config validation |
| Plan (dry run) | `terraform plan -out=/dev/null` | Ensure plan succeeds (requires AWS creds) |

If `terraform plan` fails due to missing credentials or variables, at minimum run `terraform fmt` and `terraform validate`.

---

## 📐 Project Conventions

- **Terraform:** Pin provider versions in `required_providers`; use descriptive variable names (e.g., `vault_vpc_cidr`).
- **Structure:** Modules under `modules/`; root-level config (`main.tf`, `variables.tf`, `outputs.tf`) for the single sandbox environment.
- **Commits:** Use [Conventional Commits](https://www.conventionalcommits.org/) (e.g., `feat:`, `fix:`, `docs:`).
- **Security:** No hidden egress paths; preserve air-gap integrity for the Vault VPC.

---

## 📂 Repository Layout

```
modules/       # vpc, security, sneakernet, ocp-upi
*.tf           # main.tf, variables.tf, outputs.tf (root-level sandbox config)
scripts/       # validate.sh, oc-mirror helpers
```

---

*Stay vigilant. Forge securely.*
