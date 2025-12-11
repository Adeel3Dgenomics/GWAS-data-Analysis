#!/usr/bin/env python3
"""
Quick script to extract top SNPs from PLINK association results
More efficient than bash sort for large files
"""

import sys
import pandas as pd

def extract_top_snps(input_file, output_prefix, n_top=1000):
    """Extract top N SNPs by p-value from association file"""
    
    print(f"Reading association file: {input_file}")
    
    # Read the association file
    try:
        df = pd.read_csv(input_file, delim_whitespace=True)
    except Exception as e:
        print(f"Error reading file: {e}")
        return
    
    print(f"Total SNPs in file: {len(df)}")
    
    # Get the p-value column name (usually 'P' or column 9)
    p_col = 'P' if 'P' in df.columns else df.columns[8]
    
    # Remove NA values
    df_clean = df[df[p_col].notna()].copy()
    print(f"SNPs with valid p-values: {len(df_clean)}")
    
    # Sort by p-value
    df_sorted = df_clean.sort_values(by=p_col)
    
    # Extract top 1000
    top_1000 = df_sorted.head(n_top)
    out_1000 = f"{output_prefix}/top_1000_snps.txt"
    top_1000.to_csv(out_1000, sep='\t', index=False)
    print(f"Top 1000 SNPs saved to: {out_1000}")
    
    # Extract top 100
    top_100 = df_sorted.head(100)
    out_100 = f"{output_prefix}/top_100_snps.txt"
    top_100.to_csv(out_100, sep='\t', index=False)
    print(f"Top 100 SNPs saved to: {out_100}")
    
    # Genome-wide significant (p < 5e-8)
    gw_sig = df_clean[df_clean[p_col] < 5e-8]
    out_gw = f"{output_prefix}/genome_wide_significant_snps_5e-8.txt"
    gw_sig.to_csv(out_gw, sep='\t', index=False)
    print(f"Genome-wide significant SNPs (p<5e-8): {len(gw_sig)}")
    print(f"Saved to: {out_gw}")
    
    # Suggestive (p < 1e-5)
    suggestive = df_clean[df_clean[p_col] < 1e-5]
    out_sugg = f"{output_prefix}/suggestive_snps_1e-5.txt"
    suggestive.to_csv(out_sugg, sep='\t', index=False)
    print(f"Suggestive SNPs (p<1e-5): {len(suggestive)}")
    print(f"Saved to: {out_sugg}")
    
    # Summary statistics
    out_summary = f"{output_prefix}/summary_statistics.txt"
    summary = df_clean[['CHR', 'SNP', 'BP', 'A1', p_col]].copy()
    summary.columns = ['CHR', 'SNP', 'BP', 'A1', 'P']
    summary.to_csv(out_summary, sep='\t', index=False)
    print(f"Summary statistics saved to: {out_summary}")
    
    print("\nExtraction complete!")
    return len(gw_sig), len(suggestive)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python extract_top_snps.py <input_assoc_file> <output_directory>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_dir = sys.argv[2]
    
    gw, sugg = extract_top_snps(input_file, output_dir)
    
    print(f"\n=== Summary ===")
    print(f"Genome-wide significant: {gw}")
    print(f"Suggestive: {sugg}")
