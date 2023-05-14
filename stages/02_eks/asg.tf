# locals {
#   name = "eks-production-cluster"
# }

# module "asg" {
#   source                          = "../../modules/asg"
#   name                            = "asg-${local.name}"
#   use_name_prefix                 = false
#   instance_name                   = "worker-self-managed"
#   ignore_desired_capacity_changes = true

#   min_size                  = 0
#   max_size                  = 1
#   desired_capacity          = 1
#   wait_for_capacity_timeout = 0
#   default_instance_warmup   = 300
#   health_check_type         = "EC2"
#   vpc_zone_identifier       = data.terraform_remote_state.vpc.private_subnets
#   service_linked_role_arn   = aws_iam_service_linked_role.autoscaling.arn

#   initial_lifecycle_hooks = [
#     {
#       name                 = "StartupLifeCycleHook"
#       default_result       = "CONTINUE"
#       heartbeat_timeout    = 60
#       lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
#       # This could be a rendered data resource
#       notification_metadata = jsonencode({ "hello" = "world" })
#     },
#     {
#       name                 = "TerminationLifeCycleHook"
#       default_result       = "CONTINUE"
#       heartbeat_timeout    = 180
#       lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
#       # This could be a rendered data resource
#       notification_metadata = jsonencode({ "goodbye" = "world" })
#     }
#   ]

#   instance_refresh = {
#     strategy = "Rolling"
#     preferences = {
#       checkpoint_delay       = 600
#       checkpoint_percentages = [35, 70, 100]
#       instance_warmup        = 300
#       min_healthy_percentage = 50
#     }
#     triggers = ["tag"]
#   }
#   launch_template_name = "lt-${local.name}"
# }