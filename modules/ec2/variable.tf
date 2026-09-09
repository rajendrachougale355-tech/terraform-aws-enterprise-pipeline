variable "environment" {
  type        = string
  description = "Deployment environment (dev/prod)"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for the EC2 instance"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance size"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the EC2 instance will be deployed"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of Security Group IDs attached to the instance"
}
variable "vpc_id" {
  type        = string
  description = "VPC ID where the EC2 instance will be deployed"
}