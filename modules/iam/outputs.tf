# IAM Group ARNs
output "devops_group_arn" {
  description = "ARN of the devops IAM group"
  value       = aws_iam_group.devops.arn
}

output "admin_group_arn" {
  description = "ARN of the admin IAM group"
  value       = aws_iam_group.admin.arn
}

output "developers_group_arn" {
  description = "ARN of the developers IAM group"
  value       = aws_iam_group.developers.arn
}

output "qa_engineers_group_arn" {
  description = "ARN of the qa-engineers IAM group"
  value       = aws_iam_group.qa_engineers.arn
}

output "managers_group_arn" {
  description = "ARN of the managers IAM group"
  value       = aws_iam_group.managers.arn
}

output "readonly_group_arn" {
  description = "ARN of the readonly IAM group"
  value       = aws_iam_group.readonly.arn
}

# IAM Policy ARNs
output "devops_policy_arn" {
  description = "ARN of the devops IAM policy"
  value       = aws_iam_policy.devops_policy.arn
}

output "admin_policy_arn" {
  description = "ARN of the admin IAM policy"
  value       = aws_iam_policy.admin_policy.arn
}

output "dev_access_policy_arn" {
  description = "ARN of the dev-access IAM policy"
  value       = aws_iam_policy.dev_access_policy.arn
}

output "prod_readonly_policy_arn" {
  description = "ARN of the prod-readonly IAM policy"
  value       = aws_iam_policy.prod_readonly_policy.arn
}

output "billing_access_policy_arn" {
  description = "ARN of the billing-access IAM policy"
  value       = aws_iam_policy.billing_access_policy.arn
}

output "eks_deploy_policy_arn" {
  description = "ARN of the eks-deploy IAM policy"
  value       = aws_iam_policy.eks_deploy_policy.arn
}

output "s3_access_policy_arn" {
  description = "ARN of the s3-access IAM policy"
  value       = aws_iam_policy.s3_access_policy.arn
}

output "cloudwatch_policy_arn" {
  description = "ARN of the cloudwatch IAM policy"
  value       = aws_iam_policy.cloudwatch_policy.arn
}

output "cross_account_policy_arn" {
  description = "ARN of the cross-account IAM policy"
  value       = aws_iam_policy.cross_account_policy.arn
}

output "mfa_policy_arn" {
  description = "ARN of the MFA IAM policy"
  value       = aws_iam_policy.mfa_policy.arn
}

# IAM Group Names
output "devops_group_name" {
  description = "Name of the devops IAM group"
  value       = aws_iam_group.devops.name
}

output "admin_group_name" {
  description = "Name of the admin IAM group"
  value       = aws_iam_group.admin.name
}

output "developers_group_name" {
  description = "Name of the developers IAM group"
  value       = aws_iam_group.developers.name
}

output "qa_engineers_group_name" {
  description = "Name of the qa-engineers IAM group"
  value       = aws_iam_group.qa_engineers.name
}

output "managers_group_name" {
  description = "Name of the managers IAM group"
  value       = aws_iam_group.managers.name
}

output "readonly_group_name" {
  description = "Name of the readonly IAM group"
  value       = aws_iam_group.readonly.name
}

# Summary
output "iam_groups_summary" {
  description = "Summary of all IAM groups created"
  value = {
    devops     = aws_iam_group.devops.name
    admin      = aws_iam_group.admin.name
    developers = aws_iam_group.developers.name
    qa_engineers = aws_iam_group.qa_engineers.name
    managers   = aws_iam_group.managers.name
    readonly   = aws_iam_group.readonly.name
  }
}

output "iam_policies_summary" {
  description = "Summary of all IAM policies created"
  value = {
    devops_policy        = aws_iam_policy.devops_policy.name
    admin_policy         = aws_iam_policy.admin_policy.name
    dev_access_policy    = aws_iam_policy.dev_access_policy.name
    prod_readonly_policy = aws_iam_policy.prod_readonly_policy.name
    billing_access_policy = aws_iam_policy.billing_access_policy.name
    eks_deploy_policy    = aws_iam_policy.eks_deploy_policy.name
    s3_access_policy     = aws_iam_policy.s3_access_policy.name
    cloudwatch_policy    = aws_iam_policy.cloudwatch_policy.name
    cross_account_policy = aws_iam_policy.cross_account_policy.name
    mfa_policy          = aws_iam_policy.mfa_policy.name
  }
}

# Service Role ARNs
output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster service role"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS worker node role"
  value       = aws_iam_role.eks_node_role.arn
}

output "eks_oidc_role_arn" {
  description = "ARN of the EKS OIDC service account role"
  value       = aws_iam_role.eks_oidc_role.arn
}

output "alb_controller_role_arn" {
  description = "ARN of the ALB controller role"
  value       = aws_iam_role.alb_controller_role.arn
}

output "cross_account_role_arn" {
  description = "ARN of the cross-account role"
  value       = var.enable_cross_account_access ? aws_iam_role.cross_account_role[0].arn : null
}

# Service Role Names
output "eks_cluster_role_name" {
  description = "Name of the EKS cluster service role"
  value       = aws_iam_role.eks_cluster_role.name
}

output "eks_node_role_name" {
  description = "Name of the EKS worker node role"
  value       = aws_iam_role.eks_node_role.name
}

output "eks_oidc_role_name" {
  description = "Name of the EKS OIDC service account role"
  value       = aws_iam_role.eks_oidc_role.name
}

output "alb_controller_role_name" {
  description = "Name of the ALB controller role"
  value       = aws_iam_role.alb_controller_role.name
}

output "cross_account_role_name" {
  description = "Name of the cross-account role"
  value       = var.enable_cross_account_access ? aws_iam_role.cross_account_role[0].name : null
}
