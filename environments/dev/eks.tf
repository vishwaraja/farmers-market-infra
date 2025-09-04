module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.13.1"

  cluster_name                   = var.cluster_name
  cluster_version                = "1.24"
  cluster_endpoint_public_access = true
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
#   node_security_group_ids   = [aws_security_group.eks_node_sg.id]
#   cluster_security_group_id = aws_security_group.eks_cluster_sg.id


  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
        nodeAgent = {
          enablePolicyEventLogs = "true"
        }
        enableNetworkPolicy = "true"
      })
    }
  }


  create_cluster_security_group = false
  create_node_security_group    = false

  eks_managed_node_groups = {
    node-group-1 = {
      instance_types       = ["t3.medium"]
      capacity_type        = "ON_DEMAND"
      force_update_version = true
      release_version      = "AL2_x86_64"

      min_size     = 1
      max_size     = 1
      desired_size = 1

      update_config = {
        max_unavailable_percentage = 50
      }

      labels = {
        workshop-default = "yes"
      }
    }
  }

  tags = merge(local.tags, {
    "karpenter.sh/discovery" = var.cluster_name
  })
  }

