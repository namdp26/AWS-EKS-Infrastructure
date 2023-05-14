# Create an EIP for the ALB
locals {
  name = "eks-production-cluster"

  tags = {
    Name        = local.name
    Environment = "Production"
  }
}

# Create a Security Group for the ALB
resource "aws_security_group" "eks-alb" {
  name_prefix = "allow-alb-traffic"
  vpc_id      = data.terraform_remote_state.aws_vpc.outputs.vpc_id
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
}

# Create an Application Load Balancer (ALB) and listener
resource "aws_lb" "aks-alb" {
  name               = "eks-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.terraform_remote_state.aws_vpc.outputs.public_subnets
  security_groups    = [aws_security_group.eks-alb.id]

  tags = local.tag
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
}

# Create a target group for the ALB
resource "aws_lb_target_group" "default" {
  name_prefix = "http-target group"
  port        = 90
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.aws_vpc.outputs.vpc_id
  target_type = "ip"
  health_check {
    protocol = "HTTP"
    # port         = "traffic-port"
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.tag
}

# Attach the EKS nodes to the target group
resource "aws_lb_target_group_attachment" "default" {
  target_group_arn = aws_lb_target_group.default.arn
  target_id        = module.eks.worker_groups[0].asg_name
}

# Associate the EIP with the ALB
resource "aws_lb_listener_rule" "alb_listener_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn

  action {
    type = "forward"

    target_group_arn = aws_lb_target_group.default.arn
  }

  condition {
    field  = "host-header"
    values = ["${aws_lb.alb.dns_name}"]
  }
}

# resource "aws_lb_listener_certificate" "alb_https_listener_certificate" {
#   listener_arn    = aws_lb_listener.alb_listener.arn
#   certificate_arn = aws_acm_certificate.default.arn
# }

# Map the EIP to the ALB
resource "aws_eip_association" "eip" {
  instance_id   = aws_lb.alb.arn
  allocation_id = data.terraform_remote_state.vpc.aws_eip_id
}
