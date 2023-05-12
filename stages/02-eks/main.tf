# subnet_id = data.terraform_remote_state.01-vpc.outputs.private_subnet_id  
# }

# Create EKS cluster
module "eks_cluster" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "dbiz-cluster"
  cluster_version = "1.24"
  create_iam_role = true
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






