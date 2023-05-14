# Create EKS cluster
locals {
  name            = "eks-production-cluster"
  cluster_version = "1.24"
  region          = "eu-west-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = ["us-east-1a", "us-east-1b"]

  tags = {
    Name        = local.name
    Environment = "Production"
  }
  ## AMI ID for Ubuntu 22.04 LTS amd64
  eks_ami_id              = "ami-007855ac798b5175e"
  node_group_name         = "worker-self-managed-node-group"
  node_instance_type      = "m6i.xlarge"
  node_group_min_size     = 1
  node_group_max_size     = 2
  node_group_desired_size = 0
}

module "key_pair" {
  source = "../../modules/keypair"

  key_name   = [for key_pair in var.key_pairs : key_pair.key_name]
  public_key = [for key_pair in var.key_pairs : key_pair.public_key]
  tag        = local.tag
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

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }

    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      type                     = "ingress"
      source_security_group_id = aws_security_group.additional.id
    }
  }
  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    # Test: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2319
    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      type                     = "ingress"
      source_security_group_id = aws_security_group.additional.id
    }
  }

  self_managed_node_groups = {
    worker = {
      name = local.node_group_name

      subnet_ids = data.terraform_remote_state.aws_vpc.outputs.private_subnets

      min_size     = local.node_group_min_size
      max_size     = local.node_group_max_size
      desired_size = local.node_group_desired_size

      ami_id        = local.eks_ami_id
      instance_type = local.node_instance_type

      launch_template_name            = "eks_worker_self_managed"
      launch_template_use_name_prefix = true
      launch_template_description     = "Self managed node group example launch template"

      ebs_optimized     = true
      enable_monitoring = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 80
            volume_type = "gp3"
            iops        = 3000
            throughput  = 150
            encrypted   = true
            # kms_key_id            = module.ebs_kms_key.key_arn
            delete_on_termination = true
          }
        }
      }

      vpc_security_group_ids = aws_security_group.allow_ssh.id

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      create_iam_role          = true
      iam_role_name            = "self-managed-node-group"
      iam_role_use_name_prefix = false
      iam_role_description     = "Self managed node group"
      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        additional                         = aws_iam_policy.eks_node_group.arn
      }

      timeouts = {
        create = "80m"
        update = "80m"
        delete = "80m"
      }

      tags = {
        Name = "Self managed node group"
      }
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
  tags = local.tags
}

resource "aws_security_group" "eks-security-group" {
  name_prefix = "allow_ssh_protocol"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.aws_vpc.outputs.vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_policy" "eks_node_group" {
  name        = "${local.name}-eks_node_group"
  description = "Example usage of node eks_node_group policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = local.tags
}








