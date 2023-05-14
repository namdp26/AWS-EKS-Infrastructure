# AWS-EKS-Infrastructure

**Initial AWS EKS requirement:**

**1. EC2 node IAM Roles:**

	+ AmazonEKSWorkerNodePolicy
	+ AmazonEC2ContainerRegistryReadOnly
	+ AmazonEKS_CNI_Policy (option if you want to use AWS VPC CNI Plugin)
  
**2. VPC and Subnets (for nodes networking)**

	+ at least two subnets in separate AZ to ensure HA.
	+ Node group can be in Public or Private Subnets.
  
**3. Security Group:**

	+ Control network traffic ingress or egress such as ALB.
  
**4. Amazon EKS-optimized AMI:**

**5. API Endpoint**

**6. Encryption:**

	+ Can be use AWS KMS or opensource solution such as: Hashicorp Vault
  
**7. Kube tools to interact and maintain with Cluster or Worker nodes:**

	+ kubectl
	+ aws cli
  
**8. AWS ASG**

	+ For Self-managed node or Managed node group autoscaling
	+ If you choose self-managed node group, it must be made some more config to use with Cluster Autoscaler (CA).
  
**9. Key pair**

	+ To SSH into node group it must be create and attach into EC2 nodes group.
  
**10. Extra volumes**

	+ Should be used EBS and EBS snapshot for PVC backups.
	+ In EKS Fargate is EFS for Serverless.
