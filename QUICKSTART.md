# Quick Start Guide

This guide will help you get started with the AA-GWAS Analysis Pipeline in just a few minutes.

## Prerequisites

1. **PLINK 1.9** installed or accessible via module system
2. **PLINK format files** (.bed, .bim, .fam)
3. **SLURM** cluster access (or modify for local execution)
4. *(Optional)* **Python 3.6+** with pandas, numpy, matplotlib, seaborn for plots

## Step 1: Get the Code

```bash
# Clone the repository
git clone https://github.com/yourusername/AA-GWAS.git
cd AA-GWAS

# Make scripts executable
chmod +x *.sh *.py
```

## Step 2: Prepare Your Data

Place your PLINK files in the working directory or specify the full path:

```
your_data.bed
your_data.bim
your_data.fam
```

## Step 3: Configure the Pipeline

Edit `gwas_analysis_pipeline.sh` and set your input file:

```bash
# Line 31
INPUT_PREFIX="your_data"  # Without .bed/.bim/.fam extension
```

Optionally, adjust QC thresholds (lines 38-48):

```bash
GENO_THRESHOLD=0.02      # SNP missingness
MIND_THRESHOLD=0.02      # Individual missingness
MAF_THRESHOLD=0.01       # Minor allele frequency
HWE_THRESHOLD=1e-6       # Hardy-Weinberg p-value
```

## Step 4: Run the Pipeline

### On SLURM Cluster

```bash
# Submit the job
sbatch gwas_analysis_pipeline.sh

# Check job status
squeue -u $USER

# Monitor progress
tail -f logs/your_data_*.out
```

### On Local Machine

```bash
# Run directly (not recommended for large datasets)
bash gwas_analysis_pipeline.sh

# Or run in background
nohup bash gwas_analysis_pipeline.sh > pipeline.log 2>&1 &
```

## Step 5: Check Results

The pipeline creates an `analysis_results` directory:

```bash
# View QC summary
cat analysis_results/qc/qc_summary.txt

# Top associated SNPs
head -20 analysis_results/association/top_1000_snps.txt

# Genome-wide significant hits
cat analysis_results/association/genome_wide_significant_snps_5e-8.txt

# Final report
cat analysis_results/reports/GWAS_Analysis_Final_Report.txt
```

## Step 6: Generate Plots

If you have Python with required packages:

```bash
python3 generate_plots.py \
    analysis_results/association \
    analysis_results/qc \
    analysis_results/plots
```

View plots in `analysis_results/plots/`:
- `manhattan_plot_*.png`
- `qq_plot_*.png`
- `pca_plot.png`
- `missingness_plots.png`

## Quick Individual Extraction (Alternative)

If you only need to extract individual lists:

```bash
bash extract_individuals.sh
```

This creates:
- `individuals_detailed.txt` - Full information
- `individuals_id_only.txt` - IDs only
- `cases_list.txt` - Cases
- `controls_list.txt` - Controls
- `males_list.txt` - Males
- `females_list.txt` - Females

## Troubleshooting

### Pipeline Stops Early
Check the log file in `logs/` directory for error messages.

### No Plots Generated
Install Python packages:
```bash
pip install --user pandas numpy matplotlib seaborn
```

### PLINK Not Found
Load PLINK module (if on cluster):
```bash
module load plink2/1.90b3w
```

Or install PLINK 1.9 locally.

### Out of Memory
- Increase memory in SLURM header (line 21): `#SBATCH --mem=128G`
- Or run on a subset of SNPs first

## Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Explore [CONTRIBUTING.md](CONTRIBUTING.md) to contribute
- Check [CHANGELOG.md](CHANGELOG.md) for version history

## Getting Help

- **Issues:** https://github.com/yourusername/AA-GWAS/issues
- **Email:** muhammad.muzammal@bs.qau.edu.pk

---

**Estimated Runtime:** 1-4 hours for ~900K SNPs, ~2.6K individuals (depending on hardware)
