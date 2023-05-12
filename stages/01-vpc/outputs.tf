output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_sunet" {
  value = module.vpc.private_subnets
}

output "public_sunet" {
  value = module.vpc.public_subnets
}