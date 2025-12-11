# Frequently Asked Questions (FAQ)

## General Questions

### What is this pipeline for?
This pipeline performs comprehensive Genome-Wide Association Study (GWAS) analysis, including quality control, population stratification analysis, and association testing for case-control studies.

### What data formats are supported?
The pipeline requires PLINK binary format files (.bed, .bim, .fam). If you have VCF files, convert them first:
```bash
plink --vcf yourfile.vcf.gz --make-bed --out yourdata
```

### How long does the pipeline take?
For ~900K SNPs and ~2.6K individuals: 1-4 hours on a cluster with 16 CPUs and 64GB RAM. Smaller datasets run faster.

### Can I run this on my laptop?
Yes, but for large datasets (>500K SNPs, >1K individuals), a cluster is recommended. Reduce the dataset or adjust memory settings for local runs.

## Data Questions

### What phenotype coding is required?
In the .fam file:
- **1** = Control/Unaffected
- **2** = Case/Affected
- **0 or -9** = Missing phenotype

### What about sex coding?
- **1** = Male
- **2** = Female
- **0** = Unknown

### My data is already QC'd. Can I skip QC steps?
Yes, modify the pipeline to skip steps 3-9, or run only the association analysis (Steps 13-14).

### What genome build is required?
The pipeline works with any build (hg19/GRCh37, hg38/GRCh38), but ensure consistency across all files.

## Error Messages

### "Error: No variants remaining after filters"
**Cause:** Too stringent QC thresholds removed all SNPs.
**Solution:** Lower the MAF threshold or increase GENO threshold in the script.

### "Error: No individuals remain after filters"
**Cause:** All individuals failed missingness or sex check.
**Solution:** Check your .fam file coding and lower MIND threshold.

### "Warning: Heterozygous haploid genotypes present"
**Normal:** This occurs for Y chromosome SNPs in females or mitochondrial SNPs. Usually safe to ignore unless excessive.

### "Sort command hanging" (pre-v1.0)
**Fixed in v1.0:** The pipeline now uses Python-based sorting with fallbacks. Update to latest version.

## Analysis Questions

### Why are there results with and without QC?
To compare how QC affects associations. Use QC'd results for final conclusions.

### What's the difference between 3 PCs and 10 PCs?
Different levels of population stratification correction. 3 PCs is standard; use 10 PCs if strong population structure exists.

### How many significant SNPs should I expect?
Varies by trait and sample size. Many studies find 0-10 genome-wide significant hits (p<5e-8).

### What is λ (lambda) in the Q-Q plot?
Genomic inflation factor. Values 1.0-1.05 are acceptable. >1.1 suggests population stratification or cryptic relatedness.

### What does PI_HAT mean?
Proportion of identity-by-descent. Values >0.185 suggest relatedness (e.g., 0.5 = siblings, 0.25 = half-siblings).

## Configuration Questions

### How do I change QC thresholds?
Edit these variables in `gwas_analysis_pipeline.sh` (lines 38-48):
```bash
GENO_THRESHOLD=0.02
MIND_THRESHOLD=0.02
MAF_THRESHOLD=0.01
HWE_THRESHOLD=1e-6
```

### Can I analyze quantitative traits?
Partially. The pipeline is optimized for case-control. For quantitative traits, modify Step 13-14 to use `--linear` instead of `--logistic`.

### How do I use my own covariates?
Create a covariate file and add `--covar yourfile.cov` to the association commands in Steps 13-14.

## Output Questions

### Where are the results?
All results are in `analysis_results/` directory with subdirectories:
- `qc/` - Quality control results
- `association/` - Association test results
- `plots/` - Visualization plots
- `reports/` - Summary reports

### What are .prune.in and .prune.out files?
Lists of SNPs to keep (.prune.in) and remove (.prune.out) after LD pruning for PCA.

### Can I export results to other formats?
Yes, the pipeline exports VCF, PED/MAP, and TPED/TFAM formats (Step 16).

## Plotting Questions

### Plots aren't being generated
**Cause:** Missing Python packages.
**Solution:** Install required packages:
```bash
pip install --user pandas numpy matplotlib seaborn
```

### Can I customize plot appearance?
Yes, edit `generate_plots.py` to change colors, sizes, DPI, etc.

### How do I create Manhattan plots for specific chromosomes?
Modify the `manhattan_plot()` function in `generate_plots.py` to filter by chromosome.

## Performance Questions

### How can I speed up the pipeline?
- Use more CPUs (increase `--cpus-per-task` in SLURM header)
- Increase memory (increase `--mem`)
- Run on a subset first to test
- Skip export steps if not needed (Step 16)

### The pipeline uses too much memory
- Reduce the dataset size
- Lower memory in SLURM header (but may cause failures)
- Process chromosomes separately

### Can I parallelize the analysis?
Not directly within the pipeline, but you can run separate pipelines per chromosome and combine results.

## Advanced Questions

### Can I add imputation to the pipeline?
The current pipeline doesn't include imputation. You can pre-impute your data with Michigan Imputation Server or IMPUTE2, then run the pipeline.

### How do I perform meta-analysis?
After running the pipeline on multiple cohorts, use METAL or GWAMA to meta-analyze the association results.

### Can I calculate polygenic risk scores?
Not directly. Use the association results with PRSice-2 or LDpred2 for PRS calculation.

### How do I perform gene-based tests?
Use tools like MAGMA or VEGAS2 with the association summary statistics from this pipeline.

## Troubleshooting

### Pipeline stops unexpectedly
1. Check the log file in `logs/` directory
2. Look at the error log (`.err` file)
3. Ensure PLINK is loaded/available
4. Check disk space and memory

### Results look suspicious
1. Check λ (lambda) - should be ~1.0
2. Review Q-Q plot for deviation
3. Verify phenotype coding in .fam file
4. Check for population stratification (PCA plot)
5. Review related individuals (IBD results)

### Need more help?
- **GitHub Issues:** https://github.com/yourusername/AA-GWAS/issues
- **Email:** muhammad.muzammal@bs.qau.edu.pk
- **Documentation:** See README.md and QUICKSTART.md

## Contributing

Have a question not answered here? Please:
1. Open a GitHub Discussion
2. Or submit a PR to add it to this FAQ

---

**Last Updated:** December 11, 2025
