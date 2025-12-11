# AA-GWAS Analysis Pipeline - File Structure

## Repository Organization

```
AA-GWAS/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml           # Bug report template
│   │   └── feature_request.yml      # Feature request template
│   └── workflows/
│       └── ci.yml                    # GitHub Actions CI/CD
│
├── .gitignore                        # Git ignore patterns
├── CHANGELOG.md                      # Version history and changes
├── CITATION.md                       # Citation information
├── CONTRIBUTING.md                   # Contribution guidelines
├── FAQ.md                            # Frequently asked questions
├── LICENSE                           # MIT License
├── README.md                         # Main documentation
├── QUICKSTART.md                     # Quick start guide
│
├── config.example                    # Example configuration file
├── init_repo.sh                      # Repository initialization script
├── install.sh                        # Installation script
│
├── gwas_analysis_pipeline.sh         # Main pipeline (18 steps)
├── extract_individuals.sh            # Individual list extraction
├── extract_top_snps.py              # Python SNP extraction utility
└── generate_plots.py                # Visualization generation utility
```

## File Descriptions

### Documentation Files

- **README.md**: Comprehensive project documentation with features, usage, and examples
- **QUICKSTART.md**: Step-by-step guide to get started in minutes
- **FAQ.md**: Common questions and troubleshooting
- **CHANGELOG.md**: Detailed version history and release notes
- **CITATION.md**: How to cite this work and dependencies
- **CONTRIBUTING.md**: Guidelines for contributors
- **LICENSE**: MIT License terms

### Core Scripts

- **gwas_analysis_pipeline.sh**: Main 18-step GWAS analysis pipeline
  - Quality control (steps 1-9)
  - Population structure (steps 10-12)
  - Association analysis (steps 13-15)
  - Export and visualization (steps 16-18)

- **extract_individuals.sh**: Standalone script to quickly extract individual lists
  - Detailed list with headers
  - ID-only list
  - Cases, controls, males, females

- **extract_top_snps.py**: Python utility for efficient SNP extraction
  - Handles large files (>800K SNPs)
  - Top 100, top 1000 SNPs
  - Genome-wide significant (p<5e-8)
  - Suggestive (p<1e-5)

- **generate_plots.py**: Visualization generation
  - Manhattan plots
  - Q-Q plots with genomic inflation
  - PCA plots
  - Missingness distribution plots

### Configuration & Setup

- **config.example**: Template configuration file with all parameters
- **install.sh**: Automated installation and dependency checking
- **init_repo.sh**: Git repository initialization helper

### GitHub Integration

- **.github/workflows/ci.yml**: Continuous integration
  - ShellCheck for bash scripts
  - Python linting
  - Compatibility testing (Python 3.6-3.11)

- **.github/ISSUE_TEMPLATE/**: Issue templates
  - Bug reports
  - Feature requests

- **.gitignore**: Excludes large data files and intermediate results

## Output Structure (Created by Pipeline)

When you run the pipeline, it creates:

```
analysis_results/
├── individuals_*.txt              # Individual lists
├── qc/                           # Quality control results
│   ├── qc_summary.txt
│   ├── *_pca.eigenvec
│   ├── *_ibd.genome
│   └── *_qc3_hwe.{bed,bim,fam}
├── association/                  # Association results
│   ├── *_assoc_noQC.*
│   ├── *_assoc_withQC.*
│   ├── *_logistic_3PCs.*
│   ├── *_logistic_10PCs.*
│   ├── top_100_snps.txt
│   ├── top_1000_snps.txt
│   ├── genome_wide_significant_snps_5e-8.txt
│   └── suggestive_snps_1e-5.txt
├── plots/                        # Visualization
│   ├── manhattan_plot_*.png
│   ├── qq_plot_*.png
│   ├── pca_plot.png
│   └── missingness_plots.png
├── reports/                      # Summary reports
│   └── GWAS_Analysis_Final_Report.txt
└── logs/                         # SLURM/execution logs
```

## File Sizes

Approximate sizes:
- Documentation: ~40 KB total
- Scripts: ~55 KB total
- Repository (no data): <100 KB
- With results (depends on dataset): 100 MB - 10 GB

## Maintenance

- Update CHANGELOG.md for each release
- Keep README.md in sync with code changes
- Update FAQ.md as questions arise
- Review and merge ISSUE_TEMPLATE suggestions

---

**Last Updated:** December 11, 2025
