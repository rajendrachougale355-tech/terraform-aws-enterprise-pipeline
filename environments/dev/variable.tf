variable "dev_vpc_cidr" {
  description = "CIDR block for the development VPC."
  type        = string
}

variable "dev_public_cidr" {
  description = "CIDR block for the public subnet in development."
  type        = string
}

variable "dev_private_cidr" {
  description = "CIDR block for the private subnet in development."
  type        = string
}