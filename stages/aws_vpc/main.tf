locals {
  vpc_name                 = "dbiz_prod_vpc"
  vpc_azs                  = ["us-east-1a", "us-east-1b"]
  vpc_cidr                 = "10.0.0.0/16"
  prod_vpc_private_subnets = ["10.0.10.0/24", "10.0.20.0/24"]
  prod_vpc_public_subnets  = ["10.0.100.0/24", "10.0.110.0/24"]
}

module "vpc" {
  source                 = "../../modules/vpc"
  name                   = local.name
  cidr                   = local.vpc_cidr
  azs                    = local.vpc_azs
  private_subnets        = local.prod_vpc_private_subnets
  public_subnets         = local.prod_vpc_public_subnets
  enable_nat_gateway     = true
  single_nat_gateway     = true
  reuse_nat_ips          = true
  one_nat_gateway_per_az = false
  external_nat_ip_ids    = aws_eip.nat.*.id
  enable_dns_hostnames   = true
  enable_dns_support     = true
  tags = {
    Environment = "production"
  }
}


resource "aws_eip" "nat" {
  count = 1
  vpc   = true
}