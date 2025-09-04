# =============================================================================
# NETWORKING MODULE - VPC, SUBNETS, SECURITY GROUPS
# =============================================================================
# This module creates the foundational networking infrastructure including:
# - VPC with public and private subnets across multiple AZs
# - Internet Gateway and NAT Gateway for internet access
# - Security groups for EKS cluster and worker nodes
# - Route tables and network ACLs

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values for subnet calculations
locals {
  # Calculate subnets dynamically based on VPC CIDR
  azs = slice(data.aws_availability_zones.available.names, 0, var.availability_zone_count)
  
  # Public subnets (for load balancers, bastion hosts)
  public_subnets = [
    for i, az in local.azs : cidrsubnet(var.vpc_cidr, 8, i)
  ]
  
  # Private subnets (for EKS worker nodes, databases)
  private_subnets = [
    for i, az in local.azs : cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]
  
  # Database subnets (isolated for RDS, if needed)
  database_subnets = [
    for i, az in local.azs : cidrsubnet(var.vpc_cidr, 8, i + 20)
  ]
}

# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr

  # Availability zones and subnets
  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets
  database_subnets = local.database_subnets

  # Internet Gateway and NAT Gateway
  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true
  enable_dns_support     = true

  # Subnet naming
  public_subnet_suffix  = "public"
  private_subnet_suffix = "private"
  database_subnet_suffix = "database"

  # Subnet tags for Kubernetes
  public_subnet_tags = merge(var.tags, {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  })

  private_subnet_tags = merge(var.tags, {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "karpenter.sh/discovery" = var.eks_cluster_name
  })

  database_subnet_tags = merge(var.tags, {
    "Type" = "database"
  })

  # VPC tags
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# Security Group for EKS Cluster
resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.name_prefix}-eks-cluster-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for EKS cluster control plane"

  # Allow HTTPS traffic from anywhere (for kubectl access)
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-cluster-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for EKS Worker Nodes
resource "aws_security_group" "eks_workers" {
  name_prefix = "${var.name_prefix}-eks-workers-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for EKS worker nodes"

  # Allow all traffic from EKS cluster
  ingress {
    description     = "All traffic from EKS cluster"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  # Allow HTTPS traffic from anywhere (for ALB/NLB)
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP traffic from anywhere (for ALB/NLB)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow NodePort range (30000-32767)
  ingress {
    description = "NodePort range"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-workers-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}
