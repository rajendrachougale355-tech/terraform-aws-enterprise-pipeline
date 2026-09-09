variable "vpc_id" {
  description = "The ID of the VPC where the security group will be created."
  type        = string
}

variable "environment" {
  description = "The environment for which the security group is being created (e.g., dev, staging, prod)."
  type        = string
}

