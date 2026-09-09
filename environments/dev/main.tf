# 1. Define the Cloud Provider
provider "aws" {
  region = "ap-south-1" # Mumbai
}

# 2. Call the Reusable VPC Module
module "dev_network" {
  source = "../../modules/vpc"

  vpc_cidr_block             = var.dev_vpc_cidr
  public_subnet_cidr_blocks  = [var.dev_public_cidr]
  private_subnet_cidr_blocks = [var.dev_private_cidr]
  environment                = "development"
}

module "dev_security_groups" {
  source = "../../modules/security_groups"

  vpc_id      = module.dev_network.vpc_id
  environment = "development"
}
module "dev_ec2" {
   source = "../../modules/ec2"

  vpc_id     = module.dev_network.vpc_id
  subnet_id   = module.dev_network.public_subnet_id
  security_group_ids = [module.dev_security_groups.web_sg_id]
  environment = "development"
  ami_id = "ami-01a00762f46d584a1" # Replace with your desired AMI ID
  instance_type = "t3.micro" # Replace with your desired instance type

}