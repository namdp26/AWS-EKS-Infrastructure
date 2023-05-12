subnet_id = data.terraform_remote_state.01-vpc.outputs.private_subnet_id  
}

# Create VPC, Subnets, IGW, NATGW
module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  name                   = "dbiz-vpc"
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

# Create S3 Private Bucket
module "s3_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  bucket        = "dbiz-prod"
  acl           = "private"
  force_destroy = false
  tags = {
    Terraform   = "true"
    Environment = "production"
  }
}

# Create EKS cluster
module "eks_cluster" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "dbiz-cluster"
  cluster_version = "1.24"

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  enable_irsa                     = true
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    blue = {
      scaling_config = [
        {
          min_size = 1
          max_size = 5
          metric   = "cpu"
          value    = "70"
        },
        {
          min_size = 1
          max_size = 5
          metric   = "memory"
          value    = "80"
        },
        # {
        #   min_size = 1
        #   max_size = 5
        #   metric   = "custom-metric"
        #   value    = "100"
        #   namespace = "custom-metrics-namespace"
        #   metric_name = "custom-metric-name"
        # }
      ]
      instance_types = ["m6i.xlarge"]
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "production"
  }
}

resource "aws_security_group" "eks_node_group" {
  name_prefix = "eks-node-group-sg-"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}






