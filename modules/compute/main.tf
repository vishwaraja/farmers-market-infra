# =============================================================================
# COMPUTE MODULE - EKS CLUSTER AND NODE GROUPS
# =============================================================================
# This module creates the EKS cluster and managed node groups optimized for
# minimal microservices deployment (2-3 services)

# Data sources
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# EKS Cluster Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  # VPC Configuration
  vpc_id                         = var.vpc_id
  subnet_ids                     = var.private_subnet_ids
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = true

  # Security Groups
  cluster_security_group_id = var.cluster_security_group_id
  node_security_group_id    = var.workers_security_group_id

  # Cluster Add-ons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    # Primary node group for general workloads
    primary = {
      name = "${var.name_prefix}-primary"

      # Instance configuration
      instance_types = var.instance_types
      capacity_type  = var.capacity_type
      ami_type       = "AL2_x86_64"

      # Scaling configuration
      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      # Update configuration
      update_config = {
        max_unavailable_percentage = 50
      }

      # Disk configuration
      disk_size = var.disk_size
      disk_type = "gp3"

      # Labels and taints
      labels = merge(var.node_labels, {
        node-type = "primary"
      })

      taints = var.node_taints

      # Launch template configuration
      launch_template_name        = "${var.name_prefix}-primary-lt"
      launch_template_description = "Launch template for primary node group"
      launch_template_version     = "$Latest"

      # IAM role configuration
      iam_role_name = "${var.name_prefix}-primary-node-role"

      # Tags
      tags = merge(var.tags, {
        Name = "${var.name_prefix}-primary-node-group"
      })
    }
  }

  # Cluster tags
  tags = merge(var.tags, {
    Name = var.cluster_name
  })
}

# EKS Node Group IAM Role (if not using the one from the module)
resource "aws_iam_role" "eks_node_group" {
  count = var.create_additional_iam_role ? 1 : 0
  
  name = "${var.name_prefix}-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = var.tags
}

# Attach required policies to the node group role
resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEKSWorkerNodePolicy" {
  count = var.create_additional_iam_role ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group[0].name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEKS_CNI_Policy" {
  count = var.create_additional_iam_role ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group[0].name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEC2ContainerRegistryReadOnly" {
  count = var.create_additional_iam_role ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group[0].name
}

# EBS CSI Driver IAM Role
resource "aws_iam_role" "ebs_csi_driver" {
  count = var.enable_ebs_csi ? 1 : 0
  
  name = "${var.name_prefix}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
    Version = "2012-10-17"
  })

  tags = var.tags
}

# Attach EBS CSI Driver policy
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  count = var.enable_ebs_csi ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver[0].name
}
