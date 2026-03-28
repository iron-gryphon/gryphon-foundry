variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "nest_vpc_id" {
  description = "ID of the Nest VPC"
  type        = string
}

variable "nest_public_subnet_ids" {
  description = "IDs of Nest public subnets (bastion placed in first)"
  type        = list(string)
}

variable "key_name" {
  description = "Name of existing EC2 key pair for SSH access to bastion"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for bastion"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_gb" {
  description = "Size of the root EBS volume (gp3) in GiB. Default ~20 GiB beyond typical AMI default for oc-mirror workspace, pull secret, and CLI tooling under /home/ec2-user."
  type        = number
  default     = 28
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion (e.g. [\"1.2.3.4/32\"] or [\"0.0.0.0/0\"] for any)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "oc_release" {
  description = "Release channel for openshift-client and oc-mirror on bastion (e.g. stable-4.20, 4.20.0). Must match ocp_version for mirroring."
  type        = string
}

variable "oc_mirror_pull_secret_path" {
  description = "Path on bastion to pull secret JSON; ~ expands to $HOME in profile.d"
  type        = string
}

variable "route53_hosted_zone_name" {
  description = "Route53 hosted zone name for bastion DNS record (bastion.<zone>). Leave empty to skip."
  type        = string
  default     = ""
}

variable "mirror_registry_ca_pem" {
  description = "PEM of the offline CA that signs the Nest mirror registry TLS certificate. When non-empty, installs into system trust so oc mirror can push to docker://mirror.<domain>/... without x509 unknown authority errors."
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
