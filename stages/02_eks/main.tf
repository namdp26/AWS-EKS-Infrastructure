# Create EKS cluster
locals {
  name            = "production-cluster"
  cluster_version = "1.24"
  region          = "eu-west-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
  ## AMI ID for Ubuntu 22.04 LTS amd64
  eks_ami_id              = "ami-007855ac798b5175e"
  node_group_name         = "worker-self-managed-node-group"
  node_instance_type      = "m6i.xlarge"
  node_group_min_size     = 1
  node_group_max_size     = 1
  node_group_desired_size = 1
}



module "key_pair" {
  source = "../../modules/keypair"

  key_name   = [for key_pair in var.key_pairs : key_pair.key_name]
  public_key = [for key_pair in var.key_pairs : key_pair.public_key]
}

module "eks_cluster" {
  source = "../../modules/eks"

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  region                          = local.region
  create_iam_role                 = true
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

  vpc_id                    = data.terraform_remote_state.aws_vpc.outputs.vpc_id
  subnet_ids                = data.terraform_remote_state.aws_vpc.outputs.private_subnets
  control_plane_subnet_ids  = data.terraform_remote_state.aws-vpc.outputs.private_subnets
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  self_managed_node_group_defaults = {
    # enable discovery of autoscaling groups by cluster-autoscaler
    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${local.name}" : "owned",
    }
  }

  self_managed_node_groups = {
    worker = {
      name          = local.node_group_name

      subnet_ids    = data.terraform_remote_state.aws_vpc.outputs.private_subnets
      key_name      = module.key_pair.key_pair_name

      min_size      = local.node_group_min_size
      max_size      = local.node_group_max_size
      desired_size  = local.node_group_desired_size

      ami_id        = local.eks_ami_id
      instance_type = local.node_instance_type
      launch_template_name            = "self-managed-ex"

      bootstrap_extra_args = <<-EOT
        # The admin host container provides SSH access and runs with "superpowers".
        # It is disabled by default, but can be disabled explicitly.
        [settings.host-containers.admin]
        enabled = false

        # The control host container provides out-of-band access via SSM.
        # It is enabled by default, and can be disabled if you do not expect to use SSM.
        # This could leave you with no way to access the API and change settings on an existing node!
        [settings.host-containers.control]
        enabled = true

        # extra args added
        [settings.kernel]
        lockdown = "integrity"

        [settings.kubernetes.node-labels]
        label1 = "worker"
      EOT
    }
  }
}

#   eks_managed_node_groups = {
#     blue = {
#       scaling_config = [
#         {
#           min_size = 1
#           max_size = 5
#           metric   = "cpu"
#           value    = "70"
#         },
#         {
#           min_size = 1
#           max_size = 5
#           metric   = "memory"
#           value    = "80"
#         },
#         {
#           min_size = 1
#           max_size = 5
#           metric   = "custom-metric"
#           value    = "100"
#           namespace = "custom-metrics-namespace"
#           metric_name = "custom-metric-name"
#         }
#       ]
#       instance_types = ["m6i.xlarge"]
#     }
#   }

#   tags = {
#     Terraform   = "true"
#     Environment = "production"
#   }

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






