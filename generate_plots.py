#!/usr/bin/env python3
"""
Generate GWAS visualization plots and reports
Requires: matplotlib, seaborn, pandas, numpy
"""

import sys
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

def manhattan_plot(assoc_file, output_file, title="Manhattan Plot"):
    """Create Manhattan plot from association results"""
    print(f"Creating Manhattan plot from {assoc_file}")
    
    # Read association data
    df = pd.read_csv(assoc_file, delim_whitespace=True)
    
    # Get p-value column
    p_col = 'P' if 'P' in df.columns else df.columns[8]
    
    # Remove NA values
    df = df[df[p_col].notna()].copy()
    
    # Calculate -log10(p-value)
    df['MINLOG10P'] = -np.log10(df[p_col])
    df = df[df['MINLOG10P'].notna()]
    
    # Sort by chromosome and position
    df = df.sort_values(['CHR', 'BP'])
    
    # Create chromosome colors
    df['IND'] = range(len(df))
    df_grouped = df.groupby('CHR')
    
    # Create figure
    fig, ax = plt.subplots(figsize=(16, 6))
    
    # Plot each chromosome
    colors = ['#1f77b4', '#ff7f0e']
    x_labels = []
    x_labels_pos = []
    
    for num, (name, group) in enumerate(df_grouped):
        color = colors[num % len(colors)]
        ax.scatter(group['IND'], group['MINLOG10P'], c=color, s=5, alpha=0.6, edgecolors='none')
        x_labels.append(str(name))
        x_labels_pos.append((group['IND'].iloc[0] + group['IND'].iloc[-1]) / 2)
    
    # Genome-wide significance line
    ax.axhline(y=-np.log10(5e-8), color='red', linestyle='--', linewidth=1, label='p=5e-8')
    ax.axhline(y=-np.log10(1e-5), color='blue', linestyle='--', linewidth=1, label='p=1e-5')
    
    # Format plot
    ax.set_xlabel('Chromosome', fontsize=12)
    ax.set_ylabel('-log10(P-value)', fontsize=12)
    ax.set_title(title, fontsize=14, fontweight='bold')
    ax.set_xticks(x_labels_pos)
    ax.set_xticklabels(x_labels)
    ax.legend(loc='upper right')
    ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"Manhattan plot saved to: {output_file}")
    
    # Return top SNPs
    top_snps = df.nsmallest(10, p_col)[['CHR', 'SNP', 'BP', p_col]]
    return top_snps

def qq_plot(assoc_file, output_file, title="Q-Q Plot"):
    """Create Q-Q plot from association results"""
    print(f"Creating Q-Q plot from {assoc_file}")
    
    # Read association data
    df = pd.read_csv(assoc_file, delim_whitespace=True)
    
    # Get p-value column
    p_col = 'P' if 'P' in df.columns else df.columns[8]
    
    # Remove NA values
    pvals = df[df[p_col].notna()][p_col].values
    pvals = pvals[pvals > 0]  # Remove zeros
    
    # Calculate observed -log10(p)
    observed = -np.log10(pvals)
    observed = np.sort(observed)
    
    # Calculate expected -log10(p)
    n = len(observed)
    expected = -np.log10(np.arange(1, n + 1) / (n + 1))
    
    # Calculate lambda (genomic inflation factor)
    chisq = np.percentile(pvals, 50)
    lambda_gc = np.median(np.square(np.sqrt(2) * np.abs(np.random.randn(len(pvals))))) / chisq if chisq > 0 else 1.0
    
    # Create plot
    fig, ax = plt.subplots(figsize=(8, 8))
    
    ax.scatter(expected, observed, s=10, alpha=0.6, edgecolors='none')
    
    # Diagonal line
    max_val = max(expected.max(), observed.max())
    ax.plot([0, max_val], [0, max_val], 'r--', linewidth=2, label='Expected')
    
    # Format plot
    ax.set_xlabel('Expected -log10(P-value)', fontsize=12)
    ax.set_ylabel('Observed -log10(P-value)', fontsize=12)
    ax.set_title(f'{title}\nλ = {lambda_gc:.3f}', fontsize=14, fontweight='bold')
    ax.legend(loc='upper left')
    ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"Q-Q plot saved to: {output_file}")
    return lambda_gc

def pca_plot(pca_file, output_file):
    """Create PCA plot"""
    print(f"Creating PCA plot from {pca_file}")
    
    # Read PCA data
    df = pd.read_csv(pca_file, delim_whitespace=True)
    
    # Create figure with subplots
    fig, axes = plt.subplots(1, 2, figsize=(14, 6))
    
    # PC1 vs PC2
    axes[0].scatter(df.iloc[:, 2], df.iloc[:, 3], s=20, alpha=0.6, edgecolors='none')
    axes[0].set_xlabel('PC1', fontsize=11)
    axes[0].set_ylabel('PC2', fontsize=11)
    axes[0].set_title('PC1 vs PC2', fontsize=12, fontweight='bold')
    axes[0].grid(True, alpha=0.3)
    
    # PC2 vs PC3
    axes[1].scatter(df.iloc[:, 3], df.iloc[:, 4], s=20, alpha=0.6, edgecolors='none')
    axes[1].set_xlabel('PC2', fontsize=11)
    axes[1].set_ylabel('PC3', fontsize=11)
    axes[1].set_title('PC2 vs PC3', fontsize=12, fontweight='bold')
    axes[1].grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"PCA plot saved to: {output_file}")

def missingness_plot(lmiss_file, imiss_file, output_file):
    """Create missingness plots"""
    print(f"Creating missingness plots")
    
    # Read missingness data
    snp_miss = pd.read_csv(lmiss_file, delim_whitespace=True)
    ind_miss = pd.read_csv(imiss_file, delim_whitespace=True)
    
    # Create figure
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    
    # SNP missingness
    axes[0].hist(snp_miss['F_MISS'], bins=50, edgecolor='black', alpha=0.7)
    axes[0].axvline(x=0.02, color='red', linestyle='--', label='Threshold=0.02')
    axes[0].set_xlabel('SNP Missingness Rate', fontsize=11)
    axes[0].set_ylabel('Frequency', fontsize=11)
    axes[0].set_title('SNP Missingness Distribution', fontsize=12, fontweight='bold')
    axes[0].legend()
    axes[0].grid(True, alpha=0.3)
    
    # Individual missingness
    axes[1].hist(ind_miss['F_MISS'], bins=50, edgecolor='black', alpha=0.7)
    axes[1].axvline(x=0.02, color='red', linestyle='--', label='Threshold=0.02')
    axes[1].set_xlabel('Individual Missingness Rate', fontsize=11)
    axes[1].set_ylabel('Frequency', fontsize=11)
    axes[1].set_title('Individual Missingness Distribution', fontsize=12, fontweight='bold')
    axes[1].legend()
    axes[1].grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"Missingness plots saved to: {output_file}")

def main(assoc_dir, qc_dir, output_dir):
    """Generate all plots"""
    
    output_dir = Path(output_dir)
    output_dir.mkdir(exist_ok=True)
    
    print("="*60)
    print("GWAS Visualization and Reporting")
    print("="*60)
    
    results = {}
    
    # Manhattan and Q-Q plots for different analyses
    analyses = [
        ('AA_GWAS_hg19_uniq_assoc_noQC.assoc', 'No QC'),
        ('AA_GWAS_hg19_uniq_assoc_withQC.assoc', 'With QC'),
        ('AA_GWAS_hg19_uniq_assoc.assoc', 'Standard')
    ]
    
    for assoc_file, label in analyses:
        assoc_path = Path(assoc_dir) / assoc_file
        if assoc_path.exists():
            print(f"\n--- Processing {label} ---")
            
            # Manhattan plot
            manhattan_out = output_dir / f"manhattan_plot_{label.replace(' ', '_').lower()}.png"
            try:
                top_snps = manhattan_plot(str(assoc_path), str(manhattan_out), 
                                         title=f"Manhattan Plot ({label})")
                results[f'{label}_top_snps'] = top_snps
            except Exception as e:
                print(f"Error creating Manhattan plot for {label}: {e}")
            
            # Q-Q plot
            qq_out = output_dir / f"qq_plot_{label.replace(' ', '_').lower()}.png"
            try:
                lambda_gc = qq_plot(str(assoc_path), str(qq_out), 
                                   title=f"Q-Q Plot ({label})")
                results[f'{label}_lambda'] = lambda_gc
                print(f"Genomic inflation factor (λ): {lambda_gc:.3f}")
            except Exception as e:
                print(f"Error creating Q-Q plot for {label}: {e}")
    
    # PCA plot
    pca_file = Path(qc_dir) / 'AA_GWAS_hg19_uniq_pca.eigenvec'
    if pca_file.exists():
        print("\n--- Creating PCA plot ---")
        try:
            pca_plot(str(pca_file), str(output_dir / 'pca_plot.png'))
        except Exception as e:
            print(f"Error creating PCA plot: {e}")
    
    # Missingness plots
    lmiss_file = Path(qc_dir) / 'basic_stats_preQC.lmiss'
    imiss_file = Path(qc_dir) / 'basic_stats_preQC.imiss'
    if lmiss_file.exists() and imiss_file.exists():
        print("\n--- Creating missingness plots ---")
        try:
            missingness_plot(str(lmiss_file), str(imiss_file), 
                           str(output_dir / 'missingness_plots.png'))
        except Exception as e:
            print(f"Error creating missingness plots: {e}")
    
    print("\n" + "="*60)
    print("Visualization complete!")
    print(f"All plots saved to: {output_dir}")
    print("="*60)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python generate_plots.py <assoc_dir> <qc_dir> <output_dir>")
        sys.exit(1)
    
    main(sys.argv[1], sys.argv[2], sys.argv[3])
