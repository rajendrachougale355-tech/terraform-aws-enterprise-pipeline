# 1. Define the Cloud Provider
provider "aws" {
  region = "ap-south-1" # Mumbai
}

# 2. Call the Reusable VPC Module
module "prod_network" {
  source = "../../modules/vpc"

  vpc_cidr_block             = var.prod_vpc_cidr
  public_subnet_cidr_blocks  = [var.prod_public_cidr]
  private_subnet_cidr_blocks = [var.prod_private_cidr]
  environment                = "production"
}

module "prod_security_groups" {
  source = "../../modules/security_groups"

  vpc_id      = module.prod_network.vpc_id
  environment = "production"
}
module "prod_ec2" {
  source = "../../modules/ec2"

  vpc_id             = module.prod_network.vpc_id
  subnet_id          = module.prod_network.public_subnet_id
  security_group_ids = [module.prod_security_groups.web_sg_id]
  environment        = "production"
  ami_id             = var.ami_id        # Replace with your desired AMI ID
  instance_type      = var.instance_type # Replace with your desired instance type

}