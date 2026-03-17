## Description

<!-- Describe what this PR does. Be specific about modules touched (vpc, security, sneakernet, ocp-upi, bastion) and why. -->

> **Branch workflow:** PRs should target `dev` first. Changes reach `main` only after merge from `dev`. See [CONTRIBUTING.md](../CONTRIBUTING.md) for details.

## Type of Change

- [ ] `feat:` New feature or capability
- [ ] `fix:` Bug fix or correction
- [ ] `docs:` Documentation only
- [ ] `refactor:` Code change that neither fixes a bug nor adds a feature
- [ ] `chore:` Maintenance, dependencies, or tooling

## Related Issues

<!-- Link any related issues: Fixes #123, Relates to #456 -->

Fixes #

## Pre-merge Checklist

- [ ] **No secrets:** No API keys, passwords, tokens, or credentials in code or configs
- [ ] **Terraform formatted:** Ran `terraform fmt -recursive`
- [ ] **Validation passed:** Ran `./scripts/validate.sh` (or `terraform init -backend=false && terraform validate`)
- [ ] **Plan verified:** Ran `terraform plan` successfully (or noted why not, e.g. missing AWS creds)
- [ ] **Variables:** Environment-specific values use variables; no hardcoding
- [ ] **Provider versions:** Pinned in `required_providers` (if changed)
- [ ] **Outputs:** Added/updated useful outputs for downstream projects (if applicable)

## Testing

<!-- Describe how you tested this change. If you ran `terraform plan` or `terraform apply` in a sandbox, mention it. Paste relevant plan output or logs if helpful. -->

## Security Impact

<!-- Does this change affect the air-gap, Vault isolation, or introduce new egress paths? If yes, explain. -->

**None** / **Low** / **Medium** / **High** — 

---

*Stay vigilant. Forge securely.*
