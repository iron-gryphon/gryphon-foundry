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

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion (e.g. [\"1.2.3.4/32\"] or [\"0.0.0.0/0\"] for any)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "oc_cli_version" {
  description = "OpenShift CLI version to install on bastion (e.g. 4.15.0, stable)"
  type        = string
  default     = "stable"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
