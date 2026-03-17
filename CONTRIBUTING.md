# Contributing to the Iron Gryphon Foundry 🦅

Thank you for your interest in helping us forge a more secure future for FSI AI. By contributing to the **Foundry**, you are helping build the industry standard for air-gapped, high-security MLOps environments.

We welcome contributions from Red Hatters, partners, and the wider FSI community.

---

## 🛡️ Our Philosophy
* **Security First:** Every line of code must respect the integrity of the air-gap. We do not accept changes that introduce hidden egress paths or weaken the "Vault" isolation.
* **Modularity:** This foundry is a base for many missions (Fraud, LLM, Compliance). Keep modules generic enough to be reused across different AI workloads.
* **Clarity:** Documentation is as important as the Terraform code. If a financial auditor can't understand why a resource exists, we need better comments.

---

## 🛠️ How to Contribute

### 1. Reporting Issues
Found a bug or have a feature request?
* Check the [Issues](https://github.com/iron-gryphon/gryphon-foundry/issues) tab to see if it has already been reported.
* If not, open a new issue. Use a clear title and provide as much context as possible (AWS region, OCP version, etc.).

### 2. Branch Workflow: dev → main
We use a two-stage branch workflow:
* **`dev`** — Integration branch for ongoing work. All PRs should target `dev` first.
* **`main`** — Production-ready code. Changes reach `main` only after review and merge from `dev`.

**Workflow:** Create your feature branch from `dev` → open a PR into `dev` → after review and merge, maintainers promote `dev` to `main` when ready for release.

### 3. Submitting Pull Requests (PRs)
1.  **Branch from dev:** Create your own branch from `dev` (not `main`).
2.  **Code & Format:** * Ensure all Terraform code is formatted using `terraform fmt`.
    * Use descriptive variable names (e.g., `vault_vpc_cidr` instead of `vpc_b`).
3.  **Test Your Forge:** If possible, validate your changes in a sandbox environment. Provide logs or screenshots of a successful `terraform plan` in your PR description.
4.  **Open the PR:** Target the `dev` branch. Link the PR to any relevant issues.

---

## 📜 Coding Standards

### Terraform Best Practices
* **No Hardcoding:** All environment-specific values should be variables.
* **Provider Constraints:** Always pin provider versions in `required_providers`.
* **Outputs:** Provide useful outputs (VPC IDs, Endpoint URLs) to help downstream projects (`gryphon-fraud-detection`, etc.) integrate easily.

### Commit Messages
We prefer [Conventional Commits](https://www.conventionalcommits.org/). Examples:
* `feat: add S3 replication logic for sneakernet bridge`
* `fix: resolve CIDR overlap in vault-vpc module`
* `docs: update readme with AWS Client VPN instructions`

---

## 🔒 Security Reporting
**DO NOT open a public issue for security vulnerabilities.**
If you discover a security flaw that could compromise the air-gap or expose sensitive data, please contact the **Iron Gryphon Squad** directly or follow the private reporting process in our GitHub Security tab.

---

## ⚖️ Legal
By contributing to this repository, you agree that your contributions will be licensed under the project's **Apache License 2.0**.

---
*Stay vigilant. Forge securely.*