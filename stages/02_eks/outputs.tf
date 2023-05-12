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

output "self_managed_node_groups" {
  description = "Map of attribute maps for all self managed node groups created"
  value       = module.eks.self_managed_node_groups
}

output "self_managed_node_groups_autoscaling_group_names" {
  description = "List of the autoscaling group names created by self-managed node groups"
  value       = module.eks.self_managed_node_groups_autoscaling_group_names
}

output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value       = module.eks.cluster_addons
}
