# 🌿 Branch Strategy - Dev & Prod Only

This document explains the simplified branch strategy for your Terraform infrastructure project.

## 🎯 Current Setup

### **Two-Environment Strategy:**
```
main (production) ← Manual approval required
├── dev ← Auto-deploy
└── feature/* ← PR validation only
```

## 🚀 Development Workflow

### **1. Feature Development:**
```bash
# Create feature branch
git checkout -b feature/new-service
# Work on feature
git add .
git commit -m "Add new service"
git push origin feature/new-service

# Create PR to dev branch
# GitHub runs validation
# Merge when ready
```

### **2. Quick Fixes:**
```bash
# Work directly on dev
git checkout dev
git add .
git commit -m "Quick fix"
git push origin dev
# Auto-deploys to dev environment
```

### **3. Production Deployment:**
```bash
# Merge dev to main
git checkout main
git merge dev
git push origin main
# Manual approval required for production
```

## 📋 Branch Behavior

| Branch | CI/CD Pipeline | Deployment | Approval |
|--------|----------------|------------|----------|
| **dev** | ✅ Full pipeline | ✅ Auto-deploy | ❌ None |
| **main** | ✅ Full pipeline | ✅ Deploy to prod | ✅ Manual approval |
| **feature/*** | ✅ Validation only | ❌ No deploy | ❌ None |

## 🎯 Benefits of Dev/Prod Only

### **✅ Simplicity:**
- Only 2 environments to manage
- Clear separation of concerns
- Easy to understand workflow

### **✅ Cost Effective:**
- No staging environment costs
- Reduced infrastructure overhead
- Faster development cycles

### **✅ Team Efficiency:**
- Less complexity for small teams
- Clear deployment path
- Reduced maintenance burden

## 🔧 Workflow Files

### **Development Environment:**
- **File:** `.github/workflows/terraform-dev.yml`
- **Triggers:** Push to `dev`, PR to `dev`
- **Behavior:** Auto-deploy with full validation

### **Production Environment:**
- **File:** `.github/workflows/terraform-prod.yml`
- **Triggers:** Push to `main`, manual dispatch
- **Behavior:** Manual approval required

### **Testing:**
- **File:** `.github/workflows/terraform-test.yml`
- **Triggers:** Push to any branch, PRs
- **Behavior:** Validation and testing only

## 🚀 Recommended Workflow

### **Daily Development:**
1. **Create feature branch** from `dev`
2. **Work on feature** with commits
3. **Create PR** to `dev` branch
4. **Review and merge** to `dev`
5. **Auto-deploy** to dev environment

### **Production Release:**
1. **Merge `dev`** to `main` branch
2. **Manual approval** required
3. **Deploy** to production environment
4. **Monitor** production deployment

## 📊 Environment Variables

### **Development:**
```
TF_VERSION: 1.6.0
AWS_REGION: us-east-1
ENVIRONMENT: dev
```

### **Production:**
```
TF_VERSION: 1.6.0
AWS_REGION: us-east-1
ENVIRONMENT: prod
```

## 🎯 Best Practices

### **✅ Do:**
- Use feature branches for new features
- Test thoroughly in dev environment
- Get manual approval for production
- Keep dev branch stable

### **❌ Don't:**
- Work directly on main branch
- Deploy to production without approval
- Skip validation in dev environment
- Mix feature work in dev branch

## 📝 Summary

Your simplified **dev/prod** strategy provides:

- ✅ **Clear workflow** - dev → main
- ✅ **Auto-deployment** - dev environment
- ✅ **Manual approval** - production safety
- ✅ **Cost effective** - no staging overhead
- ✅ **Team friendly** - simple to understand

Perfect for small teams and rapid development! 🚀
