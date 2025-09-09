# 🔒 Enforced Development Workflow

This document explains the enforced development workflow that ensures all changes go through dev first before reaching production.

## 🎯 Workflow Rules

### **✅ Allowed:**
- **PRs to `dev` branch** - Any branch can create PR to dev
- **Direct push to `dev`** - For quick fixes and development
- **Direct push to `main`** - Only for merging dev to prod

### **❌ Blocked:**
- **PRs to `main` branch** - Not allowed (enforced by workflow)
- **Direct feature work on `main`** - Not recommended

## 🌿 Branch Flow

```
feature/my-feature ──┐
feature/bugfix ──────┼──► dev ──► main
feature/update ──────┘     │       │
                            │       │
                            ▼       ▼
                        Auto-deploy  Manual
                        to dev      approval
                        env         for prod
```

## 🚀 Development Process

### **Step 1: Create Feature Branch**
```bash
# Create any branch name you want
git checkout -b my-awesome-feature
git checkout -b bugfix-user-login
git checkout -b add-payment-service
```

### **Step 2: Work on Feature**
```bash
# Make your changes
git add .
git commit -m "Add awesome feature"
git push origin my-awesome-feature
```

### **Step 3: Create PR to Dev**
```bash
# Create PR to dev branch (NOT main)
# GitHub will run validation
# Review and merge to dev
```

### **Step 4: Auto-Deploy to Dev**
```bash
# After merging to dev
# GitHub automatically deploys to dev environment
# Test your changes in dev environment
```

### **Step 5: Deploy to Production**
```bash
# When ready for production
git checkout main
git merge dev
git push origin main
# Manual approval required for production
```

## 📋 Workflow Triggers

### **Development Workflow (`terraform-dev.yml`):**
```yaml
on:
  push:
    branches: [dev]          # ✅ Direct push to dev
  pull_request:
    branches: [dev]          # ✅ PRs to dev only
```

### **Production Workflow (`terraform-prod.yml`):**
```yaml
on:
  push:
    branches: [main]         # ✅ Direct push to main
  workflow_dispatch:         # ✅ Manual trigger
    # ❌ NO pull_request trigger
```

## 🔒 Enforcement Benefits

### **✅ Quality Assurance:**
- All changes tested in dev first
- No direct production deployments
- Consistent development process

### **✅ Risk Reduction:**
- Production changes go through dev validation
- Manual approval for production
- Rollback capability from dev

### **✅ Team Collaboration:**
- Clear development path
- Consistent workflow for all team members
- Easy to understand process

## 🎯 Branch Protection Rules

### **Recommended GitHub Settings:**

1. **Go to:** Repository → Settings → Branches
2. **Add rule for `main` branch:**
   ```
   Branch name pattern: main
   ☑️ Require a pull request before merging
   ☑️ Require status checks to pass before merging
   ☑️ Require branches to be up to date before merging
   ☑️ Require linear history
   ☑️ Restrict pushes that create files
   ```

3. **Add rule for `dev` branch:**
   ```
   Branch name pattern: dev
   ☑️ Require status checks to pass before merging
   ☑️ Require branches to be up to date before merging
   ```

## 🚀 Example Workflows

### **Feature Development:**
```bash
# 1. Create feature branch
git checkout -b add-user-authentication
git add .
git commit -m "Add user authentication"
git push origin add-user-authentication

# 2. Create PR to dev (NOT main)
# GitHub runs validation
# Review and merge to dev

# 3. Auto-deploy to dev environment
# Test in dev environment

# 4. Deploy to production
git checkout main
git merge dev
git push origin main
# Manual approval required
```

### **Quick Fix:**
```bash
# 1. Work directly on dev
git checkout dev
git add .
git commit -m "Quick fix"
git push origin dev
# Auto-deploy to dev environment

# 2. Deploy to production
git checkout main
git merge dev
git push origin main
# Manual approval required
```

### **Hotfix (Emergency):**
```bash
# 1. Create hotfix branch
git checkout -b hotfix-critical-issue
git add .
git commit -m "Fix critical issue"
git push origin hotfix-critical-issue

# 2. Create PR to dev
# Fast-track review and merge to dev

# 3. Auto-deploy to dev
# Quick validation in dev

# 4. Deploy to production
git checkout main
git merge dev
git push origin main
# Manual approval required
```

## 📊 Workflow Summary

| Action | Dev Branch | Main Branch |
|--------|------------|-------------|
| **Create PR** | ✅ Allowed | ❌ Blocked |
| **Direct Push** | ✅ Allowed | ✅ Allowed (merge only) |
| **Auto-Deploy** | ✅ Yes | ❌ No |
| **Manual Approval** | ❌ No | ✅ Required |

## 🎯 Best Practices

### **✅ Do:**
- Create feature branches for new work
- Create PRs to dev branch
- Test thoroughly in dev environment
- Get manual approval for production
- Use descriptive branch names

### **❌ Don't:**
- Create PRs to main branch
- Work directly on main branch
- Skip dev environment testing
- Deploy to production without approval
- Use unclear branch names

## 📝 Summary

Your enforced workflow ensures:

- ✅ **All changes go through dev first**
- ✅ **No direct production deployments**
- ✅ **Manual approval for production**
- ✅ **Consistent development process**
- ✅ **Quality assurance at every step**

**Perfect for maintaining code quality and reducing production risks!** 🚀
