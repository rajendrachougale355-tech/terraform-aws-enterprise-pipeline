
variable "uat_vpc_cidr" {
  description = "CIDR block for the UAT VPC."
  type        = string
}

variable "uat_public_cidr" {
  description = "CIDR block for the public subnet in UAT."
  type        = string
}

variable "uat_private_cidr" {
  description = "CIDR block for the private subnet in UAT ."
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