#!/bin/bash

# Git initialization script for AA-GWAS Pipeline
# Run this to initialize the repository and make first commit

set -e

echo "=========================================="
echo "Initializing Git Repository"
echo "=========================================="
echo ""

# Initialize git if not already done
if [ ! -d .git ]; then
    echo "Initializing git repository..."
    git init
    echo "✓ Git repository initialized"
else
    echo "Git repository already exists"
fi

echo ""

# Configure git (optional - update with your info)
echo "Git configuration:"
echo "Please enter your name for git commits:"
read -r GIT_NAME
echo "Please enter your email for git commits:"
read -r GIT_EMAIL

git config user.name "$GIT_NAME"
git config user.email "$GIT_EMAIL"
echo "✓ Git configured"

echo ""

# Add all files
echo "Adding files to git..."
git add .
echo "✓ Files added"

echo ""

# Create initial commit
echo "Creating initial commit..."
git commit -m "Initial commit: AA-GWAS Analysis Pipeline v1.0.0

- Complete 18-step GWAS analysis pipeline
- Quality control workflow
- Association testing (with/without QC)
- Population stratification analysis
- Automated visualization
- Comprehensive documentation
"
echo "✓ Initial commit created"

echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Create a new repository on GitHub"
echo ""
echo "2. Add remote repository:"
echo "   git remote add origin https://github.com/yourusername/AA-GWAS.git"
echo ""
echo "3. Push to GitHub:"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "4. (Optional) Create development branch:"
echo "   git checkout -b develop"
echo "   git push -u origin develop"
echo ""
echo "Repository initialized successfully!"
echo ""
