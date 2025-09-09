# IAM Groups
resource "aws_iam_group" "devops" {
  name = "devops"
  path = "/"
}

resource "aws_iam_group" "admin" {
  name = "admin"
  path = "/"
}

resource "aws_iam_group" "developers" {
  name = "developers"
  path = "/"
}

resource "aws_iam_group" "qa_engineers" {
  name = "qa-engineers"
  path = "/"
}

resource "aws_iam_group" "managers" {
  name = "managers"
  path = "/"
}

resource "aws_iam_group" "readonly" {
  name = "readonly"
  path = "/"
}

# IAM Policies
resource "aws_iam_policy" "devops_policy" {
  name        = "devops-policy"
  description = "Full admin access for DevOps team to dev and prod environments"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "*"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "admin_policy" {
  name        = "admin-policy"
  description = "Full AWS admin access including IAM management"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "dev_access_policy" {
  name        = "dev-access-policy"
  description = "Development environment access for developers"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "eks:Describe*",
          "eks:List*",
          "eks:AccessKubernetesApi",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "logs:Describe*",
          "logs:Get*",
          "logs:List*",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
          ForAllValues:StringEquals = {
            "aws:TagKeys" = ["Environment"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "prod_readonly_policy" {
  name        = "prod-readonly-policy"
  description = "Production environment read-only access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "eks:Describe*",
          "eks:List*",
          "s3:GetObject",
          "s3:ListBucket",
          "logs:Describe*",
          "logs:Get*",
          "logs:List*",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
          ForAllValues:StringEquals = {
            "aws:TagKeys" = ["Environment"]
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "billing_access_policy" {
  name        = "billing-access-policy"
  description = "Billing and cost management access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:*",
          "cur:*",
          "budgets:*",
          "pricing:*",
          "aws-portal:*Billing",
          "aws-portal:*Usage",
          "aws-portal:*PaymentMethods"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "eks_deploy_policy" {
  name        = "eks-deploy-policy"
  description = "EKS deployment permissions for specific namespaces"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3-access-policy"
  description = "S3 bucket access for deployments and data"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-*",
          "arn:aws:s3:::${var.project_name}-${var.environment}-*/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "cloudwatch-policy"
  description = "CloudWatch logs and metrics access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:Describe*",
          "logs:Get*",
          "logs:List*",
          "logs:FilterLogEvents",
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      }
    ]
  })
}

# Cross-account policy for future multi-account setup
resource "aws_iam_policy" "cross_account_policy" {
  name        = "cross-account-policy"
  description = "Cross-account access for future multi-account migration"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          "arn:aws:iam::*:role/${var.project_name}-*-role"
        ]
      }
    ]
  })
}

# MFA Policy - requires MFA for all actions
resource "aws_iam_policy" "mfa_policy" {
  name        = "mfa-policy"
  description = "Requires MFA for all actions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAllExceptListedIfNoMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
}

# Attach policies to groups
resource "aws_iam_group_policy_attachment" "devops_policy_attachment" {
  group      = aws_iam_group.devops.name
  policy_arn = aws_iam_policy.devops_policy.arn
}

resource "aws_iam_group_policy_attachment" "devops_cross_account_attachment" {
  group      = aws_iam_group.devops.name
  policy_arn = aws_iam_policy.cross_account_policy.arn
}

resource "aws_iam_group_policy_attachment" "admin_policy_attachment" {
  group      = aws_iam_group.admin.name
  policy_arn = aws_iam_policy.admin_policy.arn
}

resource "aws_iam_group_policy_attachment" "developers_dev_access_attachment" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.dev_access_policy.arn
}

resource "aws_iam_group_policy_attachment" "developers_eks_deploy_attachment" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.eks_deploy_policy.arn
}

resource "aws_iam_group_policy_attachment" "developers_s3_access_attachment" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_group_policy_attachment" "developers_cloudwatch_attachment" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

resource "aws_iam_group_policy_attachment" "qa_engineers_dev_access_attachment" {
  group      = aws_iam_group.qa_engineers.name
  policy_arn = aws_iam_policy.dev_access_policy.arn
}

resource "aws_iam_group_policy_attachment" "qa_engineers_prod_readonly_attachment" {
  group      = aws_iam_group.qa_engineers.name
  policy_arn = aws_iam_policy.prod_readonly_policy.arn
}

resource "aws_iam_group_policy_attachment" "qa_engineers_eks_deploy_attachment" {
  group      = aws_iam_group.qa_engineers.name
  policy_arn = aws_iam_policy.eks_deploy_policy.arn
}

resource "aws_iam_group_policy_attachment" "qa_engineers_s3_access_attachment" {
  group      = aws_iam_group.qa_engineers.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_group_policy_attachment" "qa_engineers_cloudwatch_attachment" {
  group      = aws_iam_group.qa_engineers.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

resource "aws_iam_group_policy_attachment" "managers_prod_readonly_attachment" {
  group      = aws_iam_group.managers.name
  policy_arn = aws_iam_policy.prod_readonly_policy.arn
}

resource "aws_iam_group_policy_attachment" "managers_billing_access_attachment" {
  group      = aws_iam_group.managers.name
  policy_arn = aws_iam_policy.billing_access_policy.arn
}

resource "aws_iam_group_policy_attachment" "managers_cloudwatch_attachment" {
  group      = aws_iam_group.managers.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

resource "aws_iam_group_policy_attachment" "readonly_prod_readonly_attachment" {
  group      = aws_iam_group.readonly.name
  policy_arn = aws_iam_policy.prod_readonly_policy.arn
}

resource "aws_iam_group_policy_attachment" "readonly_cloudwatch_attachment" {
  group      = aws_iam_group.readonly.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

# Attach MFA policy to all groups
resource "aws_iam_group_policy_attachment" "devops_mfa_attachment" {
  group      = aws_iam_group.devops.name
  policy_arn = aws_iam_policy.mfa_policy.arn
}

resource "aws_iam_group_policy_attachment" "admin_mfa_attachment" {
  group      = aws_iam_group.admin.name
  policy_arn = aws_iam_policy.mfa_policy.arn
}

resource "aws_iam_group_policy_attachment" "developers_mfa_attachment" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.mfa_policy.arn
}

resource "aws_iam_group_policy_attachment" "qa_engineers_mfa_attachment" {
  group      = aws_iam_group.qa_engineers.name
  policy_arn = aws_iam_policy.mfa_policy.arn
}

resource "aws_iam_group_policy_attachment" "managers_mfa_attachment" {
  group      = aws_iam_group.managers.name
  policy_arn = aws_iam_policy.mfa_policy.arn
}

resource "aws_iam_group_policy_attachment" "readonly_mfa_attachment" {
  group      = aws_iam_group.readonly.name
  policy_arn = aws_iam_policy.mfa_policy.arn
}
