# 🦅 gryphon-foundry

**Forge secure, air-gapped foundations for FSI AI/ML workloads.**

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## 🏗️ The Vision
The **Iron Gryphon Squad** (Red Hat FSI AI) provides this repository as the "Foundry"—a baseline infrastructure-as-code (IaC) template. It is designed to establish a logically isolated, air-gapped AWS environment that replicates the security requirements of the world’s most regulated financial institutions.

This setup serves as the primary testbed and foundation for high-value FSI use cases, including **Fraud Detection**, **Disconnected LLM/RAG**, and **Automated Compliance Validation**.

---

## 📐 Architecture: The Nest & The Vault
The foundry provisions a dual-VPC architecture to simulate a true "Sneakernet" workflow:

1.  **VPC-A (The Nest):** The "connected" VPC. Used exclusively for fetching container images via `oc-mirror`, downloading datasets, and pulling Terraform providers.
2.  **VPC-B (The Vault):** The "isolated" VPC. It has **no** Internet Gateway (IGW) or NAT Gateway. This is where Red Hat OpenShift (OCP) and OpenShift AI (RHOAI) are deployed.
3.  **The Bridge:** Data movement is managed via manual/automated EBS snapshot sharing or S3 object replication between the two VPCs to maintain air-gap integrity.

---

## 📂 Repository Structure
```text
.
├── modules/
│   ├── vpc/                # Provisions VPC-A (Nest) and VPC-B (Vault)
│   ├── security/           # IAM, KMS, and Security Group configurations
│   ├── sneakernet/         # Automation for EBS/S3 data transfer
│   └── ocp-upi/            # Ignition-based OCP deployment logic
├── main.tf                 # Root-level config for sandbox
├── variables.tf
├── outputs.tf
├── scripts/                # Helper tools for oc-mirror and image sync
└── README.md
```

## 🚀 Getting Started

### Prerequisites
Before you begin forging your environment, ensure you have the following tools installed and configured:
* **Terraform 1.x+**: To manage the infrastructure lifecycle.
* **AWS CLI**: Configured with credentials that have permission to manage VPCs, EC2, and S3.
* **OpenShift Installer & CLI (oc)**: Necessary for generating ignition files and interacting with the air-gapped cluster.
* **Red Hat Pull Secret**: Required to mirror images into the local registry.

### Deployment Steps
1.  **Clone the Foundry:**
    ```bash
    git clone [https://github.com/iron-gryphon/gryphon-foundry.git](https://github.com/iron-gryphon/gryphon-foundry.git)
    cd gryphon-foundry
    ```
2.  **Initialize Terraform:**
    ```bash
    # This will download the AWS provider and initialize modules
    terraform init
    ```
3.  **Forge the Environment:**
    ```bash
    # Review the changes that will be made to your AWS account
    terraform plan -out=forge.plan

    # Apply the changes to create the Nest and the Vault
    terraform apply "forge.plan"
    ```

---

## 🔮 Downstream Projects
This foundry is built to serve as the unified infrastructure layer for the following Iron Gryphon initiatives:

* **`gryphon-fraud-detection`**: Implementing MLOps with RHOAI, Feast Feature Store, and automated drift detection triggers.
* **`gryphon-llm-rag`**: Deploying and serving Large Language Models (LLMs) in a disconnected environment using Retrieval Augmented Generation.
* **`gryphon-compliance`**: A framework for automated NIST and PCI-DSS validation specifically tailored for AI workloads in regulated environments.

---

## 🤝 Contributing
We welcome the industry to collaborate! As this is intended to be a shared community resource for the FSI sector, we encourage:
* Bug reports and feature requests via GitHub Issues.
* Security-hardened module improvements via Pull Requests.
* Documentation on regional compliance mappings.

*Please see `CONTRIBUTING.md` (coming soon) for our full contribution guidelines.*

---

## 📄 License
This project is licensed under the **Apache License 2.0**. You are free to use, modify, and distribute this code for commercial and private use, provided that the original license and copyright notice are included. See the [LICENSE](LICENSE) file for the full text.

---
**The Iron Gryphon Squad** *Empowering Financial Services with Secure, Private AI.*
