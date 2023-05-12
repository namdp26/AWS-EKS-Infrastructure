output "dbiz_eks_endpoint" {
  value = module.eks_cluster.cluster_endpoint
}

output "dbiz_eks" {
  value = module.eks_cluster.cluster_version
}