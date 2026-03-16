output "vault_private_subnet_ids" {
  description = "Vault private subnet IDs for OCP UPI node placement"
  value       = var.vault_private_subnet_ids
}

output "vault_api_security_group_id" {
  description = "Security group for OCP API server"
  value       = var.vault_api_security_group_id
}

output "vault_security_group_id" {
  description = "Security group for OCP node internal traffic"
  value       = var.vault_security_group_id
}

output "cluster_name" {
  description = "OpenShift cluster name"
  value       = var.cluster_name
}

output "upi_instructions" {
  description = "Summary of UPI deployment steps"
  value       = "Use openshift-install create ignition-configs, then provision EC2 instances in the Vault subnets. See scripts/ for oc-mirror and image sync helpers."
}

output "control_plane" {
  description = "Control plane node configuration for UPI scripts"
  value       = var.control_plane
}

output "worker" {
  description = "Standard worker node configuration for UPI scripts"
  value       = var.worker
}

output "gpu_worker" {
  description = "GPU worker node configuration for UPI scripts"
  value       = var.gpu_worker
}

output "node_summary" {
  description = "Human-readable summary of cluster node topology"
  value = {
    control_plane = "${var.control_plane.count} x ${var.control_plane.instance_type} (${var.control_plane.root_volume_size}GB root)"
    worker        = "${var.worker.count} x ${var.worker.instance_type} (${var.worker.root_volume_size}GB root)"
    gpu_worker    = var.gpu_worker.count > 0 ? "${var.gpu_worker.count} x ${var.gpu_worker.instance_type} (${var.gpu_worker.root_volume_size}GB root)" : "disabled"
  }
}
