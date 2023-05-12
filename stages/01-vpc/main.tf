module "vpc" {
  source                 = "../../modules/vpc"
  name                   = "dbiz-prod-vpc"
  cidr                   = "10.0.0.0/16"
  azs                    = ["us-east-1a", "us-east-1b"]
  private_subnets        = ["10.0.10.0/24", "10.0.20.0/24"]
  public_subnets         = ["10.0.100.0/24", "10.0.110.0/24"]
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


