#!/bin/bash

# Installation script for AA-GWAS Analysis Pipeline
# This script sets up the environment and dependencies

set -e

echo "=========================================="
echo "AA-GWAS Pipeline Installation"
echo "=========================================="
echo ""

# Check if PLINK is available
echo "Checking for PLINK..."
if command -v plink &> /dev/null; then
    echo "✓ PLINK found: $(plink --version | head -n1)"
else
    echo "⚠ PLINK not found in PATH"
    echo "  Please install PLINK 1.9 or load via module system:"
    echo "  module load plink2/1.90b3w"
fi

echo ""

# Check Python version
echo "Checking Python version..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    echo "✓ Python found: $PYTHON_VERSION"
    
    # Check if version is 3.6+
    MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
    
    if [ "$MAJOR" -ge 3 ] && [ "$MINOR" -ge 6 ]; then
        echo "  Python version is suitable (3.6+)"
    else
        echo "⚠ Python 3.6+ recommended for plotting features"
    fi
else
    echo "⚠ Python 3 not found"
fi

echo ""

# Optional: Install Python packages
echo "Python packages for visualization (optional):"
echo "  - pandas"
echo "  - numpy"
echo "  - matplotlib"
echo "  - seaborn"
echo ""

read -p "Install Python packages now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing Python packages..."
    pip install --user pandas numpy matplotlib seaborn
    echo "✓ Python packages installed"
else
    echo "Skipping Python package installation"
    echo "To install later: pip install --user pandas numpy matplotlib seaborn"
fi

echo ""

# Make scripts executable
echo "Making scripts executable..."
chmod +x gwas_analysis_pipeline.sh
chmod +x extract_individuals.sh
chmod +x extract_top_snps.py
chmod +x generate_plots.py
echo "✓ Scripts are now executable"

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Place your PLINK files (.bed, .bim, .fam) in the working directory"
echo "2. Edit gwas_analysis_pipeline.sh to set INPUT_PREFIX to your filename"
echo "3. Run: sbatch gwas_analysis_pipeline.sh"
echo ""
echo "For more information, see README.md"
echo ""
