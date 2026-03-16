# OCP-UPI Module: OpenShift User-Provisioned Infrastructure
# Placeholder for Ignition-based OCP deployment in the Vault VPC.
# Downstream: Use openshift-install create ignition-configs, then provision
# bootstrap, master, and worker nodes in vault_private_subnet_ids.
#
# This module prepares the foundation (subnets, security groups) and outputs
# the values needed for openshift-install and manual UPI steps.

# -----------------------------------------------------------------------------
# Placeholder: OCP UPI requires openshift-install binary and pull secret.
# The actual deployment is typically done via:
# 1. openshift-install create ignition-configs
# 2. Create EC2 instances in Vault subnets with ignition configs
# 3. Bootstrap, then approve CSRs, etc.
#
# This module outputs the infrastructure IDs for use by external UPI scripts.
# -----------------------------------------------------------------------------

# No resources created - this module serves as a pass-through for UPI inputs.
# Future: Add EC2 instance profiles, load balancer, or ignition data sources.
