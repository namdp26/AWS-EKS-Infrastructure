output "key_pair_name" {
  description = "The list SSH key pair Added to EKS Node Group"
  value       = module.key_pair.key_pair_name
}

output "dbiz_eks_endpoint" {
  value = module.eks_cluster.cluster_endpoint
}

output "dbiz_eks" {
  value = module.eks_cluster.cluster_version
}