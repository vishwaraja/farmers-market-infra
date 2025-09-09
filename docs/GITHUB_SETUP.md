# 🔧 GitHub Variables and Secrets Setup

This document explains how to configure GitHub repository variables and secrets for your Terraform CI/CD workflows.

## 🎯 Overview

Your workflows now use GitHub's built-in variables and secrets instead of hardcoded values. This makes your infrastructure more flexible and secure.

## 📋 Required GitHub Variables

Go to your repository: **Settings** → **Secrets and variables** → **Actions** → **Variables** tab

### **Repository Variables:**

| Variable Name | Description | Default Value | Example |
|---------------|-------------|---------------|---------|
| `TF_VERSION` | Terraform version to use | `1.6.0` | `1.6.0` |
| `AWS_REGION` | AWS region for deployment | `us-east-1` | `us-east-1` |
| `ENVIRONMENT` | Environment name | `dev` | `dev` |

## 🔐 Required GitHub Secrets

Go to your repository: **Settings** → **Secrets and variables** → **Actions** → **Secrets** tab

### **AWS Secrets:**

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID | AWS IAM Console |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | AWS IAM Console |
| `AWS_ROLE_ARN` | AWS Role ARN (optional) | AWS IAM Console |

### **Notification Secrets:**

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `SLACK_WEBHOOK_URL` | Slack webhook URL | Slack App Settings |

## 🚀 Setup Instructions

### **1. Set Repository Variables:**

1. Go to your GitHub repository
2. Click **Settings** tab
3. Click **Secrets and variables** → **Actions**
4. Click **Variables** tab
5. Click **New repository variable**
6. Add each variable:

```
Name: TF_VERSION
Value: 1.6.0

Name: AWS_REGION  
Value: us-east-1

Name: ENVIRONMENT
Value: dev
```

### **2. Set Repository Secrets:**

1. In the same **Secrets and variables** → **Actions** page
2. Click **Secrets** tab
3. Click **New repository secret**
4. Add each secret:

```
Name: AWS_ACCESS_KEY_ID
Value: AKIAIOSFODNN7EXAMPLE

Name: AWS_SECRET_ACCESS_KEY
Value: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

Name: AWS_ROLE_ARN
Value: arn:aws:iam::123456789012:role/GitHubActionsRole

Name: SLACK_WEBHOOK_URL
Value: https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
```

## 🔧 How It Works

### **Variable Fallbacks:**
```yaml
env:
  TF_VERSION: ${{ vars.TF_VERSION || '1.6.0' }}
  AWS_REGION: ${{ vars.AWS_REGION || 'us-east-1' }}
  ENVIRONMENT: ${{ vars.ENVIRONMENT || 'dev' }}
```

- If `TF_VERSION` variable is set → use that value
- If not set → use default `1.6.0`

### **AWS Role Assumption:**
```yaml
- name: 🔑 Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ env.AWS_REGION }}
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    role-session-name: ${{ github.workflow }}-${{ github.run_id }}
```

- Uses IAM role assumption for better security
- Creates unique session names for each workflow run

## 🎯 Benefits

### **✅ Flexibility:**
- Change Terraform version without code changes
- Switch AWS regions easily
- Update environment names dynamically

### **✅ Security:**
- Secrets are encrypted and never visible in logs
- IAM role assumption for temporary credentials
- No hardcoded sensitive values

### **✅ Environment-Specific:**
- Different variables for different environments
- Easy to manage multiple AWS accounts
- Centralized configuration management

## 🔍 Environment-Specific Variables

### **For Different Environments:**

You can set different variables for different environments:

**Development:**
```
TF_VERSION: 1.6.0
AWS_REGION: us-east-1
ENVIRONMENT: dev
```

**Staging:**
```
TF_VERSION: 1.6.0
AWS_REGION: us-west-2
ENVIRONMENT: staging
```

**Production:**
```
TF_VERSION: 1.6.0
AWS_REGION: us-east-1
ENVIRONMENT: prod
```

## 🚨 Security Best Practices

### **1. Use IAM Roles (Recommended):**
```yaml
# Instead of long-term access keys
role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
```

### **2. Rotate Secrets Regularly:**
- Update AWS access keys every 90 days
- Rotate Slack webhook URLs if compromised

### **3. Use Least Privilege:**
- Only grant necessary permissions to IAM roles
- Use environment-specific roles

### **4. Monitor Usage:**
- Check AWS CloudTrail for role usage
- Monitor GitHub Actions logs

## 🔧 Troubleshooting

### **Variable Not Found:**
```
Error: Variable 'TF_VERSION' not found
```
**Solution:** Set the variable in GitHub repository settings

### **Secret Not Found:**
```
Error: Secret 'AWS_ACCESS_KEY_ID' not found
```
**Solution:** Set the secret in GitHub repository settings

### **AWS Authentication Failed:**
```
Error: AWS credentials invalid
```
**Solution:** Check AWS access keys and role ARN

### **Slack Notification Failed:**
```
Error: Slack webhook invalid
```
**Solution:** Verify Slack webhook URL

## 📝 Summary

Your workflows now use GitHub's built-in variables and secrets system:

- ✅ **Variables** for non-sensitive configuration
- ✅ **Secrets** for sensitive credentials
- ✅ **Fallback values** for missing variables
- ✅ **IAM role assumption** for better security
- ✅ **Environment-specific** configuration

This makes your infrastructure more flexible, secure, and maintainable! 🚀
