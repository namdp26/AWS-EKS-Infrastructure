resource "aws_launch_template" "eks_worker_node_group" {
  name = "foo"

  block_device_mappings {
    device_name = "/dev/sdc"

    ebs {
      volume_size = 80
    }
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  cpu_options {
    core_count       = 4
    threads_per_core = 2
  }

  credit_specification {
    cpu_credits = "standard"
  }

  disable_api_stop        = true
  disable_api_termination = false

  ebs_optimized = true

  iam_instance_profile {
    name = ""
  }

#   image_id = "ami-test"

  instance_initiated_shutdown_behavior = "stop"

  instance_type = "t2.micro"

#   kernel_id = "test"

  key_name      = module.key_pair.key_pair_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    subnet_id = data.terraform_remote_state.aws_vpc.outputs.private_subnets
  }

#   placement {
#     availability_zone = "us-east-1a"
#   }

#   ram_disk_id = ""



  vpc_security_group_ids = aws_security_group.allow_ssh.id

  tag_specifications {
    resource_type = "eks-worker"

    tags = {
      Name = "Production"
    }
  }

#   user_data = filebase64("${path.module}/example.sh")
}

resource "aws_security_group" "allow_ssh" {
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