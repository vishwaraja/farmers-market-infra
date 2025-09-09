# 💰 Infracost Setup Guide

This guide shows you how to set up and use Infracost for cost optimization in your Terraform infrastructure project.

## 🎯 What is Infracost?

Infracost is a CLI tool that shows cost estimates for your Terraform infrastructure changes before you deploy them. It integrates with your CI/CD pipeline to show cost impact in pull requests.

## 🚀 Quick Setup

### **1. Get Infracost API Key (Free)**

1. Go to [Infracost Cloud](https://infracost.io/cloud)
2. Sign up with your GitHub account
3. Get your API key from the dashboard
4. **Free tier includes:**
   - Unlimited cost estimates
   - PR comments
   - Cost history
   - Team collaboration

### **2. Add API Key to GitHub Secrets**

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add:
   ```
   Name: INFRACOST_API_KEY
   Value: your-infracost-api-key-here
   ```

### **3. Test Locally (Optional)**

```bash
# Install Infracost CLI
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Test with your dev environment
infracost breakdown --path=environments/dev
```

## 🔧 How It Works in Your Workflow

### **Current Integration:**

Your CI/CD workflow now includes Infracost:

```yaml
- name: 💰 Infracost Setup
  uses: infracost/infracost-gh-action@v0.10
  with:
    api_key: ${{ secrets.INFRACOST_API_KEY }}
    
- name: 💰 Generate Infracost Report
  run: |
    infracost breakdown --path=environments/dev \
      --format=json --out-file=infracost-dev.json
    infracost comment github --path=infracost-dev.json \
      --github-token=${{ github.token }} \
      --repo=${{ github.repository }} \
      --pull-request=${{ github.event.pull_request.number }} \
      --behavior=update
```

### **What Happens:**

1. **Terraform plan** is generated
2. **Infracost analyzes** the plan
3. **Cost estimate** is calculated
4. **PR comment** is posted automatically
5. **Team reviews** cost impact before merging

## 📊 Example PR Comments

### **New Infrastructure:**
```markdown
## 💰 Infrastructure cost estimate

| Project | Previous | New | Diff |
|---------|----------|-----|------|
| **Total** | $0.00/month | $48.23/month | +$48.23/month |

### 📊 Cost breakdown

| Resource | Previous | New | Diff |
|----------|----------|-----|------|
| **aws_instance.eks_node** | $0.00/month | $15.20/month | +$15.20/month |
| **aws_lb.application** | $0.00/month | $16.05/month | +$16.05/month |
| **aws_nat_gateway.main** | $0.00/month | $32.40/month | +$32.40/month |
| **aws_cloudfront_distribution.frontend** | $0.00/month | $1.20/month | +$1.20/month |
| **aws_s3_bucket.storage** | $0.00/month | $0.38/month | +$0.38/month |

### 💡 Cost optimization suggestions

- **Consider using Spot instances** for EKS nodes to save ~60% on compute costs
- **Review NAT Gateway usage** - consider single NAT Gateway for dev environment
```

### **Cost Changes:**
```markdown
## 💰 Infrastructure cost estimate

| Project | Previous | New | Diff |
|---------|----------|-----|------|
| **Total** | $48.23/month | $52.15/month | +$3.92/month |

### 📊 Cost breakdown

| Resource | Previous | New | Diff |
|----------|----------|-----|------|
| **aws_instance.eks_node** | $15.20/month | $18.50/month | +$3.30/month |
| **aws_lb.application** | $16.05/month | $16.05/month | $0.00/month |
| **aws_nat_gateway.main** | $32.40/month | $32.40/month | $0.00/month |

### ⚠️ Cost increase detected

- **EKS node instance type changed** from t3.small to t3.medium
- **Monthly cost increase**: $3.30/month
- **Annual impact**: $39.60/year
```

## 🎯 Benefits for Your Project

### **✅ Cost Visibility:**
- **See cost impact** before deployment
- **Prevent budget surprises**
- **Make informed decisions**

### **✅ Team Collaboration:**
- **Everyone sees** cost implications
- **Discuss alternatives** in PR comments
- **Optimize together**

### **✅ Cost Control:**
- **Set budget thresholds**
- **Get alerts** for large changes
- **Track cost trends**

## 🚀 Usage Examples

### **1. Create a PR:**
```bash
# Create feature branch
git checkout -b add-monitoring

# Make changes to terraform files
# Add monitoring resources

# Commit and push
git add .
git commit -m "Add monitoring infrastructure"
git push origin add-monitoring

# Create PR to dev branch
# Infracost will automatically comment with cost estimate
```

### **2. Review Cost Impact:**
- **Check PR comments** for cost estimate
- **Review cost breakdown** by resource
- **Consider optimization** suggestions
- **Discuss alternatives** with team

### **3. Optimize Costs:**
```bash
# Modify terraform.tfvars
capacity_type = "SPOT"  # Use spot instances

# Commit changes
git add .
git commit -m "Switch to spot instances for cost savings"
git push origin add-monitoring

# Infracost will show cost reduction in PR
```

## 🔧 Advanced Configuration

### **Cost Budgets:**
```yaml
# Add to your workflow
- name: 💰 Generate Infracost Report
  run: |
    infracost breakdown --path=environments/dev \
      --format=json --out-file=infracost-dev.json
    infracost comment github --path=infracost-dev.json \
      --github-token=${{ github.token }} \
      --repo=${{ github.repository }} \
      --pull-request=${{ github.event.pull_request.number }} \
      --behavior=update \
      --show-skipped=false \
      --cost-threshold=10  # Alert if cost increase > $10/month
```

### **Multiple Environments:**
```yaml
# Add cost comparison between environments
- name: 💰 Compare Environments
  run: |
    infracost diff --path=environments/dev \
      --compare-to=environments/production \
      --format=json --out-file=infracost-diff.json
```

## 📈 Cost Optimization Tips

### **1. Use Spot Instances:**
```hcl
# In terraform.tfvars
capacity_type = "SPOT"  # 60-70% cost savings
```

### **2. Right-size Resources:**
```hcl
# Use appropriate instance types
instance_types = ["t3.small"]  # For dev
instance_types = ["t3.medium"] # For production
```

### **3. Optimize Storage:**
```hcl
# Use appropriate storage classes
storage_class = "STANDARD_IA"  # For infrequent access
```

### **4. Review NAT Gateways:**
```hcl
# Use single NAT Gateway for dev
single_nat_gateway = true
```

## 🎯 Expected Results

### **Your Current Setup:**
- **Monthly cost**: ~$48/month
- **Cost visibility**: Real-time in PRs
- **Optimization**: Automatic suggestions
- **Team awareness**: Everyone sees costs

### **Potential Savings:**
- **Spot instances**: 60-70% savings on compute
- **Right-sizing**: 20-30% savings on resources
- **Storage optimization**: 10-20% savings on storage
- **Total potential savings**: 30-50% cost reduction

## 📝 Summary

Infracost gives you:

- ✅ **Real-time cost estimates** in PRs
- ✅ **Cost optimization** suggestions
- ✅ **Team cost awareness**
- ✅ **Budget control** and alerts
- ✅ **Free tier** with unlimited usage

**Perfect for your ~$48/month infrastructure!** 🚀

## 🔗 Useful Links

- [Infracost Documentation](https://www.infracost.io/docs/)
- [Infracost Cloud](https://infracost.io/cloud)
- [Cost Optimization Guide](https://www.infracost.io/docs/features/cost_optimization/)
- [GitHub Integration](https://www.infracost.io/docs/features/cli_commands/infracost_comment_github/)
