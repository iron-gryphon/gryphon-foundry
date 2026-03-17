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

**Cluster sizing** (control plane, worker, GPU worker counts and instance types) is configured in the **UPI project** (e.g., gryphon-ocp-upi), not in this foundry.

---

## 📂 Repository Structure
```text
.
├── modules/
│   ├── vpc/                # Provisions VPC-A (Nest) and VPC-B (Vault)
│   ├── security/           # IAM, KMS, and Security Group configurations
│   ├── sneakernet/         # Automation for EBS/S3 data transfer
│   ├── ocp-upi/            # Ignition-based OCP deployment logic
│   └── bastion/            # Internet-accessible jump host with OCP CLI
├── main.tf                 # Root-level config for sandbox
├── variables.tf
├── outputs.tf
├── scripts/                # Helper tools for oc-mirror and image sync
└── README.md
```

## 🚀 Getting Started

### Request an AWS Environment

1. Log in to [https://catalog.demo.redhat.com/](https://catalog.demo.redhat.com/)
2. From the catalog, select **"AWS Blank Open Environment"**
3. You will receive:
   - The sandbox environment host name (Route53 hosted zone name)
   - The AWS credentials

Use the received information to set up your environment. The hosted zone name is used to create a `bastion.<zone>` DNS record for the jump host. See [SETUP.md](SETUP.md) for credential configuration.

### Prerequisites
Before you begin forging your environment, ensure you have the following tools installed and configured:
* **Terraform 1.x+**: To manage the infrastructure lifecycle.
* **AWS CLI**: Configured with credentials that have permission to manage VPCs, EC2, S3, and KMS. See [SETUP.md](SETUP.md) for credential configuration.
* **OpenShift Installer & CLI (oc)**: Necessary for generating ignition files and interacting with the air-gapped cluster.
* **Red Hat Pull Secret**: Required to mirror images into the local registry.

### Deployment Steps
1.  **Clone the Foundry:**
    ```bash
    git clone [https://github.com/iron-gryphon/gryphon-foundry.git](https://github.com/iron-gryphon/gryphon-foundry.git)
    cd gryphon-foundry
    ```
2.  **Configure Variables:**
    ```bash
    cp terraform.tfvars.example terraform.tfvars
    # Edit terraform.tfvars with:
    #   - AWS region, CIDRs, and availability zones
    #   - route53_hosted_zone_name: the hosted zone from your sandbox (e.g. sandbox.example.com)
    #   - bastion_key_name: name of your EC2 key pair
    ```
3.  **Configure AWS Credentials:**
    Use environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) or `aws configure`. See [SETUP.md](SETUP.md) for details.
4.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
5.  **Forge the Environment:**
    ```bash
    terraform plan -var-file=terraform.tfvars -out=forge.plan
    terraform apply "forge.plan"
    ```

### Bastion Host

A bastion host is deployed in the Nest (connected) VPC and can reach the OCP API in the Vault via VPC peering. It comes pre-installed with the OpenShift CLI (`oc`) for cluster management.

**Prerequisites:** Create an EC2 key pair before applying:

```bash
aws ec2 create-key-pair --key-name gryphon-bastion --query 'KeyMaterial' --output text > bastion-key.pem
chmod 400 bastion-key.pem
```

Set `bastion_key_name = "gryphon-bastion"` in `terraform.tfvars`.

**Connect:**

```bash
# When Route53 hosted zone is configured, use the bastion hostname:
terraform output bastion_hostname   # e.g. bastion.sandbox.example.com

# SSH to the bastion (by hostname when Route53 is set, or by IP)
ssh -i bastion-key.pem ec2-user@$(terraform output -raw bastion_hostname)
# Without Route53: ssh -i bastion-key.pem ec2-user@$(terraform output -raw bastion_public_ip)
```

**Use OCP CLI:** Once connected, use `oc login` with your cluster's API URL (e.g. `https://api.<cluster>.<domain>:6443`) after the OpenShift cluster is deployed. Restrict SSH access by setting `bastion_ssh_allowed_cidrs` to your VPN or office IP range.

### Accessing the OpenShift Web Console (sshuttle / SOCKS)

To reach the OpenShift web console from your laptop over the bastion:

1. **Install sshuttle** (transparent VPN over SSH):
   ```bash
   brew install sshuttle   # macOS
   ```

2. **Run sshuttle** (use `bastion_hostname` when Route53 is configured, otherwise `bastion_public_ip`; replace `10.1.0.0/16` with your Vault VPC CIDR if different):
   ```bash
   sshuttle -r ec2-user@$(terraform output -raw bastion_hostname) 10.1.0.0/16 -e "ssh -i bastion-key.pem"
   ```

3. **Add a hosts entry** for the console (get the LB IP from `oc get svc -n openshift-console` on the bastion):
   ```bash
   # /etc/hosts: <console-lb-ip>  console-openshift-console.apps.<cluster>.<domain>
   ```

4. **Open the console** in your browser: `https://console-openshift-console.apps.<cluster>.<domain>`

**Alternative:** Use a SOCKS proxy: `ssh -D 1080 -i bastion-key.pem ec2-user@$(terraform output -raw bastion_hostname)`, then configure your browser to use `socks5://127.0.0.1:1080`.

---

## 🔧 UPI Project: Expectations and Consuming Foundry Outputs

The foundry provisions infrastructure only. The **UPI project** (e.g., `gryphon-ocp-upi`) is responsible for deploying the OpenShift cluster. This section describes what the UPI project must do and how to consume foundry outputs.

### What the UPI Project Is Expected to Do

1. **Cluster sizing** – Define control plane, worker, and GPU worker counts, instance types, and root volume sizes.
2. **Generate ignition configs** – Run `openshift-install create ignition-configs` (with pull secret from a secure source).
3. **Provision EC2 instances** – Create bootstrap, control plane, and worker nodes in the **Vault private subnets** using the security groups provided by the foundry.
4. **Create load balancers** – NLB/ALB for the API server and ingress (console, `*.apps`).
5. **Create Route53 records** – In the sandbox hosted zone:
   - `api.<cluster>.<domain>` → API load balancer
   - `*.apps.<cluster>.<domain>` → Ingress load balancer
6. **Complete bootstrap** – Approve CSRs and wait for the cluster to become ready.

### How to Pass Foundry Outputs to the UPI Project

From the **gryphon-foundry** directory (after `terraform apply`), export outputs for the UPI project:

**Option A: JSON (for Ansible, scripts, or automation)**

```bash
cd gryphon-foundry
terraform output -json > foundry-outputs.json
```

**Option B: Individual outputs (for manual use or CI)**

```bash
# Required for UPI
terraform output -raw ocp_upi_subnet_ids      # Vault private subnet IDs for node placement
terraform output -raw vault_api_security_group_id
terraform output -raw vault_security_group_id
terraform output -raw ocp_cluster_name        # e.g. gryphon-ocp
terraform output -raw ocp_base_domain         # e.g. sandbox3704.opentlc.com (empty if no Route53)

# Bastion (for SSH jump host, oc login)
terraform output -raw bastion_hostname        # or bastion_public_ip if no Route53
```

**Option C: Environment variables (for Ansible extra vars or shell)**

```bash
export FOUNDRY_OCP_SUBNET_IDS=$(terraform output -raw ocp_upi_subnet_ids | tr -d '"[]' | tr ',' ' ')
export FOUNDRY_VAULT_API_SG=$(terraform output -raw vault_api_security_group_id)
export FOUNDRY_VAULT_SG=$(terraform output -raw vault_security_group_id)
export FOUNDRY_CLUSTER_NAME=$(terraform output -raw ocp_cluster_name)
export FOUNDRY_BASE_DOMAIN=$(terraform output -raw ocp_base_domain)
export FOUNDRY_BASTION=$(terraform output -raw bastion_hostname)
```

### Foundry Outputs Reference (UPI-relevant)

| Output | Description |
|--------|-------------|
| `ocp_upi_subnet_ids` | Vault private subnet IDs for OCP node placement |
| `vault_api_security_group_id` | Security group for API server (6443) and ingress (443) |
| `vault_security_group_id` | Security group for node-to-node traffic |
| `ocp_cluster_name` | Cluster name (used in `api.<cluster>.<domain>`) |
| `ocp_base_domain` | Base domain for DNS (Route53 zone); empty if not set |
| `bastion_hostname` | Bastion FQDN for SSH (when Route53 is configured) |
| `bastion_public_ip` | Bastion IP (fallback when no Route53) |

The UPI project should use the bastion as the jump host for deployment and `oc login` after the cluster is ready.

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
