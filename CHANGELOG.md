# Changelog

All notable changes to the AA-GWAS Analysis Pipeline will be documented in this file.

## [1.0.0] - 2025-12-11

### Added
- Initial release of comprehensive GWAS analysis pipeline
- 18-step automated workflow from raw data to results
- Quality control with multiple filtering strategies
- Association testing with and without QC
- PCA-adjusted association analysis (3 and 10 PCs)
- Population stratification analysis (PCA, IBD)
- Automated visualization generation (Manhattan, Q-Q, PCA plots)
- Individual list extraction utilities
- Comprehensive reporting system
- Python-based efficient SNP sorting (`extract_top_snps.py`)
- Visualization tools (`generate_plots.py`)
- Robust 3-tier fallback system for large file processing

### Features
- **Quality Control**
  - SNP missingness filter (2%)
  - Individual missingness filter (2%)
  - MAF filter (1%)
  - Hardy-Weinberg equilibrium test (p<1e-6)
  - Sex discordance detection
  - Heterozygosity outlier detection
  - Relatedness checking (IBD)

- **Association Analysis**
  - Basic chi-square test
  - Logistic regression
  - Linear regression (for quantitative traits)
  - PCA-adjusted analysis
  - Comparative analysis (with/without QC)

- **Visualization**
  - Manhattan plots
  - Q-Q plots with genomic inflation factor
  - PCA scatter plots
  - Missingness distribution plots

- **Export Formats**
  - VCF (compressed)
  - PED/MAP
  - TPED/TFAM
  - Summary statistics

### Technical
- Supports datasets up to 926K+ SNPs
- Handles 2K+ individuals efficiently
- Memory-optimized sorting algorithms
- SLURM cluster compatibility
- Detailed logging with timestamps
- Error handling and graceful degradation

### Documentation
- Comprehensive README with examples
- Inline code documentation
- Troubleshooting guide
- Best practices references

## [0.9.0] - 2025-12-11 (Beta)

### Changed
- Fixed sort command hanging on large files
- Replaced bash sort with Python pandas for efficiency
- Added fallback mechanisms for sorting

### Fixed
- Pipeline stopping at Step 15 (sorting issue)
- Memory overflow on large SNP datasets
- --write-samples flag compatibility with PLINK 1.9

## [0.5.0] - 2025-12-11 (Alpha)

### Added
- Initial pipeline structure
- Basic QC workflow
- Association testing framework

---

## Release Notes

### Version 1.0.0 Highlights

This release represents a production-ready, battle-tested GWAS analysis pipeline with:
- **Robustness:** Multiple fallback mechanisms ensure completion
- **Completeness:** 18 comprehensive analysis steps
- **Flexibility:** Works with or without optional dependencies
- **Quality:** Follows GWAS community best practices
- **Usability:** Clear documentation and examples

### Known Limitations
- Requires PLINK 1.9 (PLINK 2.0 not yet supported)
- Visualization requires Python 3.6+ with specific libraries
- Designed for case-control studies (quantitative traits partially supported)
- Large memory requirements for >1M SNPs (64GB recommended)

### Future Enhancements
- PLINK 2.0 support
- Imputation integration
- Meta-analysis workflows
- Polygenic risk score calculation
- Gene-based association tests
- Interactive HTML reports
