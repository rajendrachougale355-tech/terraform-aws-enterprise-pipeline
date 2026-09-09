
variable "prod_vpc_cidr" {
  description = "CIDR block for the production VPC."
  type        = string
}

variable "prod_public_cidr" {
  description = "CIDR block for the public subnet in production."
  type        = string
}

variable "prod_private_cidr" {
  description = "CIDR block for the private subnet in production."
  type        = string
}
variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance."
  type        = string
}
variable "instance_type" {
  description = "The instance type for the EC2 instance."
  type        = string
}