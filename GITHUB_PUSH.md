# GitHub Push Instructions

Follow these steps to push the AA-GWAS Pipeline to GitHub.

## Prerequisites

- Git installed on your system
- GitHub account created
- SSH keys or personal access token configured (recommended)

## Step 1: Create GitHub Repository

1. Go to https://github.com
2. Click the **+** icon → **New repository**
3. Fill in:
   - **Repository name:** `AA-GWAS` (or your preferred name)
   - **Description:** "Comprehensive GWAS Analysis Pipeline with QC and Visualization"
   - **Visibility:** Choose Public or Private
   - **DO NOT** initialize with README (we already have one)
4. Click **Create repository**

## Step 2: Initialize Local Repository

From the `AA_GWAS_GitHub` directory:

```bash
cd /path/to/AA_GWAS_GitHub

# Initialize git (if not done)
git init

# Configure your identity
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: AA-GWAS Analysis Pipeline v1.0.0"
```

Or use the provided script:

```bash
bash init_repo.sh
```

## Step 3: Connect to GitHub

Replace `yourusername` with your GitHub username:

```bash
# Add remote repository
git remote add origin https://github.com/yourusername/AA-GWAS.git

# Verify remote
git remote -v
```

For SSH (recommended):
```bash
git remote add origin git@github.com:yourusername/AA-GWAS.git
```

## Step 4: Push to GitHub

```bash
# Rename branch to main (if needed)
git branch -M main

# Push to GitHub
git push -u origin main
```

## Step 5: Verify Upload

1. Go to `https://github.com/yourusername/AA-GWAS`
2. Verify all files are present:
   - README.md should display automatically
   - Scripts should be visible
   - Documentation should be accessible

## Step 6: Create Development Branch (Optional)

```bash
# Create and switch to develop branch
git checkout -b develop

# Push develop branch
git push -u origin develop

# Set develop as default branch on GitHub (optional)
# Go to Settings → Branches → Default branch
```

## Step 7: Configure Repository Settings

On GitHub, go to **Settings**:

1. **General**:
   - Update description
   - Add website URL (if any)
   - Add topics: `gwas`, `bioinformatics`, `plink`, `genetics`, `pipeline`

2. **Options**:
   - Enable Issues
   - Enable Wiki (optional)
   - Disable Projects (optional)

3. **Branches**:
   - Add branch protection rules for `main` (optional)

4. **Actions**:
   - Enable GitHub Actions for CI/CD

## Step 8: Add GitHub Releases (Optional)

Create the first release:

1. Go to **Releases** → **Create a new release**
2. Tag version: `v1.0.0`
3. Release title: `AA-GWAS Pipeline v1.0.0`
4. Description: Copy from CHANGELOG.md
5. Click **Publish release**

## Quick Command Summary

```bash
# Full setup in one go
cd AA_GWAS_GitHub
git init
git config user.name "Your Name"
git config user.email "your.email@example.com"
git add .
git commit -m "Initial commit: AA-GWAS Pipeline v1.0.0"
git branch -M main
git remote add origin https://github.com/yourusername/AA-GWAS.git
git push -u origin main
```

## Using Personal Access Token

If using HTTPS and two-factor authentication:

1. Generate token: GitHub → Settings → Developer settings → Personal access tokens → Generate new token
2. Give permissions: `repo` (full control)
3. Copy the token
4. Use token as password when pushing:
   ```bash
   git push -u origin main
   Username: yourusername
   Password: [paste your token]
   ```

## Troubleshooting

### Error: "remote origin already exists"
```bash
git remote remove origin
git remote add origin https://github.com/yourusername/AA-GWAS.git
```

### Error: "failed to push some refs"
```bash
# Pull first, then push
git pull origin main --allow-unrelated-histories
git push -u origin main
```

### Large file warning
```bash
# Remove from staging
git rm --cached large_file.bed
# Add to .gitignore, then commit
```

## Keeping Repository Updated

After making changes:

```bash
# Check status
git status

# Add changes
git add .

# Commit with message
git commit -m "Description of changes"

# Push to GitHub
git push origin main
```

## Cloning Repository Later

To clone your repository elsewhere:

```bash
git clone https://github.com/yourusername/AA-GWAS.git
cd AA-GWAS
bash install.sh
```

---

**Need Help?**
- GitHub Docs: https://docs.github.com
- Git Docs: https://git-scm.com/doc
- Contact: muhammad.muzammal@bs.qau.edu.pk
