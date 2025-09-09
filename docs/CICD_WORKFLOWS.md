# CI/CD Workflows Documentation

This document describes the GitHub Actions CI/CD workflows for the Terraform infrastructure project.

## 🚀 **Workflow Overview**

### **Workflow Structure**
```
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD WORKFLOW STRUCTURE                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │     DEV     │    │   STAGING   │    │    PROD     │     │
│  │ Environment │    │ Environment │    │ Environment │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │ Auto Deploy │    │ Auto Deploy │    │ Manual      │     │
│  │ on Push     │    │ on Push     │    │ Approval    │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 📋 **Available Workflows**

### **1. Dev Environment Workflow** (`.github/workflows/terraform-dev.yml`)

**Triggers:**
- Push to `dev` branch
- Pull request to `dev` branch

**Jobs:**
1. **Validate**: Terraform validation, linting, security scanning
2. **Plan**: Generate Terraform plan
3. **Apply**: Auto-deploy to dev environment (on push)
4. **PR Comment**: Post plan results to PR

**Features:**
- ✅ **Auto-deploy**: Automatically deploys on push to dev
- ✅ **PR Comments**: Shows plan output in PR comments
- ✅ **Infrastructure Testing**: Tests deployed infrastructure
- ✅ **Slack Notifications**: Notifies team of deployment status

### **2. Staging Environment Workflow** (`.github/workflows/terraform-staging.yml`)

**Triggers:**
- Push to `staging` branch
- Pull request to `staging` branch

**Jobs:**
1. **Validate**: Terraform validation, linting, security scanning
2. **Plan**: Generate Terraform plan
3. **Apply**: Auto-deploy to staging environment (on push)
4. **PR Comment**: Post plan results to PR

**Features:**
- ✅ **Auto-deploy**: Automatically deploys on push to staging
- ✅ **PR Comments**: Shows plan output in PR comments
- ✅ **Infrastructure Testing**: Tests deployed infrastructure
- ✅ **Slack Notifications**: Notifies team of deployment status

### **3. Production Environment Workflow** (`.github/workflows/terraform-prod.yml`)

**Triggers:**
- Push to `main` branch
- Manual workflow dispatch

**Jobs:**
1. **Validate**: Terraform validation, linting, security scanning
2. **Plan**: Generate Terraform plan
3. **Cost Estimation**: Infracost cost analysis
4. **Approval**: Manual approval required
5. **Apply**: Deploy to production (after approval)
6. **Rollback**: Emergency rollback capability

**Features:**
- ✅ **Manual Approval**: Requires manual approval before deployment
- ✅ **Cost Estimation**: Shows cost impact before deployment
- ✅ **Infrastructure Testing**: Tests deployed infrastructure
- ✅ **Rollback**: Emergency rollback capability
- ✅ **Slack Notifications**: Notifies team of deployment status

### **4. Testing Workflow** (`.github/workflows/terraform-test.yml`)

**Triggers:**
- Push to any branch
- Pull request to any branch

**Jobs:**
1. **Static Analysis**: Terraform validation and formatting
2. **Linting**: TFLint security and best practices
3. **Security Scan**: Checkov security scanning
4. **Cost Estimation**: Infracost cost analysis
5. **Compliance Test**: Terraform compliance testing
6. **Integration Test**: End-to-end infrastructure testing
7. **Test Summary**: Comprehensive test results summary

**Features:**
- ✅ **Comprehensive Testing**: All types of testing in one workflow
- ✅ **Multi-Environment**: Tests all environments
- ✅ **Cost Analysis**: Cost estimation for all environments
- ✅ **Compliance**: Security and best practices compliance
- ✅ **Integration**: End-to-end infrastructure testing

## 🔧 **Setup Instructions**

### **1. GitHub Secrets**

Add the following secrets to your GitHub repository:

```yaml
# Required Secrets
AWS_ACCESS_KEY_ID: "your-aws-access-key"
AWS_SECRET_ACCESS_KEY: "your-aws-secret-key"
SLACK_WEBHOOK: "your-slack-webhook-url"

# Optional Secrets
INFRACOST_API_KEY: "your-infracost-api-key"
GITHUB_TOKEN: "your-github-token"
```

### **2. GitHub Environments**

Create the following environments in your GitHub repository:

```yaml
# Environments
development:
  - No protection rules
  - Auto-deploy enabled

staging:
  - Required reviewers: 1
  - Auto-deploy enabled

production:
  - Required reviewers: 2
  - Wait timer: 5 minutes
  - Manual approval required
```

### **3. Branch Protection Rules**

Set up branch protection rules:

```yaml
# Branch Protection
main:
  - Require pull request reviews: 2
  - Require status checks: All workflows
  - Require branches to be up to date: Yes

staging:
  - Require pull request reviews: 1
  - Require status checks: All workflows
  - Require branches to be up to date: Yes

dev:
  - Require pull request reviews: 1
  - Require status checks: All workflows
  - Require branches to be up to date: Yes
```

## 🎯 **Workflow Usage**

### **Development Workflow**

```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Make changes
# Edit Terraform files

# 3. Create PR to dev branch
git push origin feature/new-feature
# Create PR to dev branch

# 4. Review PR
# Team reviews the PR
# Tests run automatically

# 5. Merge to dev
# Auto-deploys to dev environment
```

### **Staging Workflow**

```bash
# 1. Create PR from dev to staging
git checkout staging
git merge dev
git push origin staging

# 2. Auto-deploys to staging
# Tests run automatically
# Team can test in staging environment
```

### **Production Workflow**

```bash
# 1. Create PR from staging to main
git checkout main
git merge staging
git push origin main

# 2. Manual approval required
# Team reviews and approves
# Cost estimation shown
# Deploys to production
```

## 🧪 **Testing Strategy**

### **Testing Pyramid**

```
┌─────────────────────────────────────────┐
│           E2E Tests                     │ ← Integration Tests
│        (Infrastructure, Services)       │
├─────────────────────────────────────────┤
│        Integration Tests                │ ← Service Tests
│      (API, Database, External)          │
├─────────────────────────────────────────┤
│          Unit Tests                     │ ← Static Analysis
│    (Validation, Linting, Security)      │
└─────────────────────────────────────────┘
```

### **Test Types**

1. **Static Analysis**
   - Terraform validation
   - Code formatting
   - Syntax checking

2. **Linting**
   - TFLint security checks
   - Best practices validation
   - Resource configuration

3. **Security Scanning**
   - Checkov security scanning
   - Vulnerability detection
   - Compliance checking

4. **Cost Estimation**
   - Infracost cost analysis
   - Budget validation
   - Cost optimization

5. **Compliance Testing**
   - Security compliance
   - Best practices compliance
   - Policy validation

6. **Integration Testing**
   - Infrastructure testing
   - Service testing
   - End-to-end testing

## 📊 **Monitoring and Notifications**

### **Slack Notifications**

The workflows send notifications to Slack for:

- ✅ **Deployment Success**: When deployments complete successfully
- ❌ **Deployment Failure**: When deployments fail
- 🔔 **Approval Required**: When manual approval is needed
- ⚠️ **Rollback**: When rollback is executed

### **GitHub Notifications**

- **PR Comments**: Plan output and test results
- **Status Checks**: Required for merging
- **Workflow Runs**: Complete execution history
- **Artifacts**: Plan files and test results

## 🚨 **Troubleshooting**

### **Common Issues**

#### **1. Workflow Failures**
```bash
# Check workflow logs
# Go to Actions tab in GitHub
# Click on failed workflow
# Review logs for specific errors
```

#### **2. Permission Issues**
```bash
# Check AWS credentials
# Verify GitHub secrets
# Check environment permissions
```

#### **3. State Lock Issues**
```bash
# Check DynamoDB locks table
# Verify state file access
# Check for concurrent runs
```

#### **4. Test Failures**
```bash
# Check infrastructure status
# Verify service endpoints
# Check resource availability
```

### **Debugging Steps**

1. **Check Workflow Logs**: Review detailed logs in GitHub Actions
2. **Verify Secrets**: Ensure all required secrets are configured
3. **Check Permissions**: Verify AWS and GitHub permissions
4. **Test Locally**: Run tests locally to reproduce issues
5. **Check Resources**: Verify AWS resources are accessible

## 🔄 **Workflow Customization**

### **Adding New Tests**

```yaml
# Add new test job
new-test:
  name: New Test
  runs-on: ubuntu-latest
  steps:
    - name: Run New Test
      run: ./scripts/new-test.sh
```

### **Modifying Notifications**

```yaml
# Customize Slack notifications
- name: Custom Notification
  uses: 8398a7/action-slack@v3
  with:
    status: custom
    text: "Custom notification message"
```

### **Adding New Environments**

```yaml
# Add new environment workflow
name: Terraform New Environment
on:
  push:
    branches: [new-env]
```

## 📚 **Best Practices**

### **1. Workflow Design**
- ✅ **Fail Fast**: Stop on first failure
- ✅ **Parallel Jobs**: Run independent jobs in parallel
- ✅ **Caching**: Cache dependencies and artifacts
- ✅ **Idempotent**: Workflows should be repeatable

### **2. Security**
- ✅ **Secrets Management**: Use GitHub secrets
- ✅ **Least Privilege**: Minimal required permissions
- ✅ **Audit Trails**: Log all activities
- ✅ **Access Control**: Restrict workflow access

### **3. Monitoring**
- ✅ **Status Checks**: Required for merging
- ✅ **Notifications**: Real-time updates
- ✅ **Logging**: Comprehensive logging
- ✅ **Metrics**: Track success rates and duration

## 🎯 **Summary**

This CI/CD setup provides:

- ✅ **Automated Deployment**: Dev and staging auto-deploy
- ✅ **Manual Approval**: Production requires approval
- ✅ **Comprehensive Testing**: All types of testing
- ✅ **Cost Management**: Cost estimation and validation
- ✅ **Security**: Security scanning and compliance
- ✅ **Monitoring**: Real-time notifications and logging
- ✅ **Rollback**: Emergency rollback capability

The workflows follow industry best practices and provide a robust, secure, and efficient CI/CD pipeline for your Terraform infrastructure! 🚀
