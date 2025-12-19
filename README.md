# GWAS Analysis Pipeline

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PLINK](https://img.shields.io/badge/PLINK-v1.90b3w-blue.svg)](https://www.cog-genomics.org/plink/1.9/)
[![Python](https://img.shields.io/badge/Python-3.6%2B-green.svg)](https://www.python.org/)

GWAS Analysis Pipeline is a complete, end-to-end solution for performing rigorous genome-wide association studies to identify genetic variants associated with complex traits and diseases. This 18-step automated pipeline implements GWAS best practices, from raw genotype data to publication-ready results.

**Biological Background**: Genome-Wide Association Studies (GWAS) are powerful tools for identifying single nucleotide polymorphisms (SNPs) and other genetic variants associated with phenotypic traits, disease susceptibility, or treatment response. By analyzing hundreds of thousands to millions of genetic variants across the genome in large populations, GWAS can uncover novel biological pathways, disease mechanisms, and potential therapeutic targets. This pipeline is specifically designed for case-control studies, comparing allele frequencies between affected individuals (cases) and unaffected controls to identify disease-associated loci.

===================================================================

## 🎯 Features

- **18-Step Comprehensive Pipeline** - From raw data to publication-ready results
- **Robust QC Workflow** - Missingness, MAF, HWE, heterozygosity, sex checks
- **Multiple Association Tests** - With and without QC, with PCA adjustment
- **Population Stratification** - PCA analysis and IBD/relatedness checking
- **Automated Visualization** - Manhattan plots, Q-Q plots, PCA plots
- **Fallback Mechanisms** - Guaranteed completion even with limited resources
- **Detailed Reporting** - Comprehensive summary reports with recommendations

## 📊 Dataset

- **Genome Build:** hg19/GRCh37
- **Total SNPs:** > 26M variants
- **Total Individuals:** > 150K samples
- **Study Type:** Case-control association study

## 🚀 Quick Start

### Prerequisites

```bash
# Required
module load plink2/1.90b3w

# Optional (for plotting)
pip install --user pandas numpy matplotlib seaborn
```

### Basic Usage

```bash
# Clone the repository
cd /your/working/directory

# Submit the complete pipeline
sbatch gwas_analysis_pipeline.sh

# OR extract individuals only
bash extract_individuals.sh
```

### Manual Plot Generation

```bash
python3 generate_plots.py \
    analysis_results/association \
    analysis_results/qc \
    analysis_results/plots
```

## 📁 Pipeline Structure

### Input Files
```
AA_GWAS_hg19_uniq.bed    # Binary genotype data
AA_GWAS_hg19_uniq.bim    # Variant information
AA_GWAS_hg19_uniq.fam    # Sample information
```

### Output Structure
```
analysis_results/
├── individuals_*.txt              # Individual lists (cases, controls, etc.)
├── qc/                           # Quality control results
│   ├── qc_summary.txt
│   ├── *_pca.eigenvec           # Principal components
│   ├── *_ibd.genome             # Relatedness estimates
│   └── *_qc3_hwe.{bed,bim,fam} # QC-filtered data
├── association/                  # Association test results
│   ├── *_assoc_noQC.*           # Results without QC
│   ├── *_assoc_withQC.*         # Results with QC
│   ├── *_logistic_3PCs.*        # PCA-adjusted (3 PCs)
│   ├── *_logistic_10PCs.*       # PCA-adjusted (10 PCs)
│   ├── top_100_snps.txt
│   ├── top_1000_snps.txt
│   ├── genome_wide_significant_snps_5e-8.txt
│   └── suggestive_snps_1e-5.txt
├── plots/                        # Visualization plots
│   ├── manhattan_plot_*.png
│   ├── qq_plot_*.png
│   ├── pca_plot.png
│   └── missingness_plots.png
├── reports/                      # Summary reports
│   └── GWAS_Analysis_Final_Report.txt
└── logs/                         # SLURM logs
```

## 🔬 Pipeline Steps

### Quality Control (Steps 1-9)
1. Extract individual lists
2. Generate basic statistics
3. Identify high-missingness individuals
4. Sex check and discordance detection
5. Missing data filters (SNP >2%, Individual >2%)
6. Minor allele frequency filter (MAF <1%)
7. Hardy-Weinberg equilibrium test (p<1e-6)
8. Heterozygosity outlier detection (mean ± 3 SD)
9. Generate detailed QC report

### Population Structure (Steps 10-12)
10. LD pruning for PCA (window=50, step=5, r²=0.2)
11. Principal component analysis (20 PCs)
12. Identity-by-descent / relatedness checking (PI_HAT>0.185)

### Association Analysis (Steps 13-15)
13. Association tests (with and without QC)
14. PCA-adjusted association (3 and 10 PCs)
15. Extract significant and top SNPs

### Export & Visualization (Steps 16-18)
16. Export to multiple formats (VCF, PED/MAP, TPED/TFAM)
17. Generate visualization plots
18. Create final comprehensive report

## ⚙️ Configuration

### Quality Control Thresholds

Edit these parameters in `gwas_analysis_pipeline.sh`:

```bash
GENO_THRESHOLD=0.02      # SNP missingness (2%)
MIND_THRESHOLD=0.02      # Individual missingness (2%)
MAF_THRESHOLD=0.01       # Minor allele frequency (1%)
HWE_THRESHOLD=1e-6       # Hardy-Weinberg p-value
LD_R2=0.2                # LD pruning r² threshold
IBD_THRESHOLD=0.185      # Relatedness threshold
```

### SLURM Settings

```bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=04:00:00
#SBATCH --partition=serial
```

## 📈 Significance Thresholds

- **Genome-wide significant:** p < 5×10⁻⁸
- **Suggestive:** p < 1×10⁻⁵

## 🛠️ Scripts Description

### Core Pipeline
- **`gwas_analysis_pipeline.sh`** - Main 18-step GWAS pipeline
- **`extract_individuals.sh`** - Quick individual list extraction

### Utilities
- **`extract_top_snps.py`** - Efficient SNP extraction (Python)
- **`generate_plots.py`** - Visualization generation (Python)

### Documentation
- **`README.md`** - This file
- **`LICENSE`** - MIT License

## 📊 Output Files Description

### Individual Lists
- `individuals_detailed.txt` - Full FAM file information with headers
- `individuals_id_only.txt` - FID and IID only
- `cases_list.txt` - Case/affected individuals
- `controls_list.txt` - Control/unaffected individuals

### Association Results
- `*.assoc` - Basic chi-square association test
- `*.assoc.logistic` - Logistic regression results
- `*.assoc.adjusted` - Multiple testing corrected p-values
- `*_noQC.*` - Results using original data (no filters)
- `*_withQC.*` - Results using QC-filtered data
- `*_3PCs.*` / `*_10PCs.*` - PCA-adjusted results

### Plots
- **Manhattan plots** - Genome-wide association signals
- **Q-Q plots** - P-value distribution with λ (genomic inflation)
- **PCA plots** - Population structure visualization
- **Missingness plots** - QC metrics distribution

## 🔍 Key Features

### Robust Execution
- **3-tier fallback system** for sorting (Python → AWK → Simple extraction)
- **Error handling** at each step
- **Graceful degradation** if optional tools unavailable
- **Detailed logging** with timestamps

### Comprehensive QC
- Pre and post-QC statistics
- Sex discordance flagging
- Heterozygosity outlier detection
- Relatedness identification
- Multiple filtering strategies

### Comparative Analysis
- Results **with and without QC**
- Multiple covariate adjustments
- Top hits extraction
- Genome-wide and suggestive thresholds

## 📖 Usage Examples

### Extract Specific Individuals

```bash
# Extract only cases
awk '$6==2 {print $1, $2}' AA_GWAS_hg19_uniq.fam > my_cases.txt

# Create subset
plink --bfile AA_GWAS_hg19_uniq --keep my_cases.txt --make-bed --out cases_only
```

### Run Association on Specific Chromosome

```bash
plink --bfile analysis_results/qc/AA_GWAS_hg19_uniq_qc3_hwe \
      --chr 1 \
      --assoc \
      --out chr1_association
```

### Generate Custom Plots

```bash
python3 extract_top_snps.py \
    analysis_results/association/AA_GWAS_hg19_uniq_assoc.assoc \
    custom_output_dir
```

## 🐛 Troubleshooting

### Pipeline stops at sorting
**Fixed!** The pipeline now uses efficient Python-based sorting with fallbacks.

### "No individuals remain after filters"
Check FAM file phenotype coding (1=control, 2=case). Lower QC thresholds if needed.

### Sex check warnings
Review `qc/sex_discordance.txt`. Update sex information or remove flagged samples.

### Related individuals detected
Check `qc/related_pairs.txt`. Consider removing one from each related pair.

### Python plots fail
Install required packages:
```bash
pip install --user pandas numpy matplotlib seaborn
```

## 📚 References

### Software
- **PLINK 1.9:** Chang CC, et al. (2015) Second-generation PLINK. *GigaScience*, 4.
  - Website: https://www.cog-genomics.org/plink/1.9/

### GWAS Best Practices
- Anderson CA, et al. (2010) Data quality control in genetic case-control association studies. *Nat Protoc*, 5(9):1564-73.
- Price AL, et al. (2006) Principal components analysis corrects for stratification in genome-wide association studies. *Nat Genet*, 38(8):904-9.
- Purcell S, et al. (2007) PLINK: a tool set for whole-genome association and population-based linkage analyses. *Am J Hum Genet*, 81(3):559-75.

## 👥 Contributors

- **Adeel** - Pipeline development and implementation
- **Contact:** Muhammad-Adeel@omrf.org/m.muzammal.adeel@outlook.com

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- OMRF for computational resources
- PLINK development team
- GWAS community for best practices

## 📞 Support

For questions or issues:
- **GitHub Issues:** https://github.com/Adeel3Dgenomics/GWAS-data-Analysis/issues
- **Email:** Muhammad-Adeel@omrf.org

## 🚀 Quick Links

- [Quick Start Guide](QUICKSTART.md)
- [FAQ](FAQ.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Citation Information](CITATION.md)
- [Changelog](CHANGELOG.md)
- [GitHub Push Instructions](GITHUB_PUSH.md)

---

**Version:** 1.0.0  
**Last Updated:** December 11, 2025  
**License:** MIT



