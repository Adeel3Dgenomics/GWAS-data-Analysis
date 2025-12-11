#!/bin/bash
################################################################################
# GWAS Analysis Pipeline using PLINK 1.9
# Author: Adeel
# Date: December 11, 2025
# Description: Comprehensive GWAS quality control and association analysis
################################################################################
#SBATCH --job-name=AA_GWAS_Pipeline
#SBATCH --output=logs/AA_GWAS_%j.out
#SBATCH --error=logs/AA_GWAS_%j.err
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --partition=serial
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=muhammad.muzammal@bs.qau.edu.pk

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Function to log messages with timestamps
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if file exists
check_file() {
    if [ ! -f "$1" ]; then
        log_message "ERROR: Required file not found: $1"
        exit 1
    fi
}

# Error handling function
error_exit() {
    log_message "ERROR: $1"
    exit 1
}

# Load PLINK module
log_message "Loading PLINK module..."
ml plink2/1.90b3w || error_exit "Failed to load PLINK module"

# Set working directory
WORKDIR="/s/nath-lab/adeel/AA-GWAS/AA_GWAS"
cd "$WORKDIR" || error_exit "Failed to change to working directory: $WORKDIR"

# Define input files and parameters
INPUT_PREFIX="AA_GWAS_hg19_uniq"
OUTPUT_DIR="analysis_results"
QC_DIR="${OUTPUT_DIR}/qc"
ASSOC_DIR="${OUTPUT_DIR}/association"
LOG_DIR="${OUTPUT_DIR}/logs"
PLOTS_DIR="${OUTPUT_DIR}/plots"
REPORT_DIR="${OUTPUT_DIR}/reports"

# QC thresholds
GENO_THRESHOLD=0.02      # SNP missingness threshold (stricter: 2%)
MIND_THRESHOLD=0.02      # Individual missingness threshold (stricter: 2%)
MAF_THRESHOLD=0.01       # Minor allele frequency threshold
HWE_THRESHOLD=1e-6       # Hardy-Weinberg equilibrium p-value
LD_WINDOW=50             # LD pruning window size
LD_STEP=5                # LD pruning step size
LD_R2=0.2                # LD pruning r-squared threshold
IBD_THRESHOLD=0.185      # PI_HAT threshold for relatedness

# Create output directories
mkdir -p "$OUTPUT_DIR" "$QC_DIR" "$ASSOC_DIR" "$LOG_DIR" "$PLOTS_DIR" "$REPORT_DIR"

# Check input files exist
check_file "${INPUT_PREFIX}.bed"
check_file "${INPUT_PREFIX}.bim"
check_file "${INPUT_PREFIX}.fam"

log_message "========================================="
log_message "GWAS Analysis Pipeline Started"
log_message "Input: ${INPUT_PREFIX}"
log_message "Working Directory: ${WORKDIR}"
log_message "Output Directory: ${OUTPUT_DIR}"
log_message "========================================="
log_message ""
log_message "QC Parameters:"
log_message "  - SNP missingness: ${GENO_THRESHOLD}"
log_message "  - Individual missingness: ${MIND_THRESHOLD}"
log_message "  - MAF threshold: ${MAF_THRESHOLD}"
log_message "  - HWE p-value: ${HWE_THRESHOLD}"
log_message "  - IBD threshold: ${IBD_THRESHOLD}"
log_message "========================================="

################################################################################
# Step 1: Extract Individual List
################################################################################
log_message "[Step 1/18] Extracting individual list..."

# Create detailed sample information file
awk '{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6}' ${INPUT_PREFIX}.fam > "${OUTPUT_DIR}/all_individuals.txt"

# Add header
{
    echo -e "FID\tIID\tFather_ID\tMother_ID\tSex\tPhenotype"
    cat "${OUTPUT_DIR}/all_individuals.txt"
} > "${OUTPUT_DIR}/individuals_detailed.txt"

# Create simple ID list (FID IID only)
awk '{print $1"\t"$2}' ${INPUT_PREFIX}.fam > "${OUTPUT_DIR}/individuals_id_only.txt"

# Create case/control lists
awk '$6==2 {print $1"\t"$2}' ${INPUT_PREFIX}.fam > "${OUTPUT_DIR}/cases_list.txt"
awk '$6==1 {print $1"\t"$2}' ${INPUT_PREFIX}.fam > "${OUTPUT_DIR}/controls_list.txt"

log_message "Individual lists saved to ${OUTPUT_DIR}/"
log_message "  - Total individuals: $(wc -l < ${INPUT_PREFIX}.fam)"
log_message "  - Cases: $(wc -l < ${OUTPUT_DIR}/cases_list.txt)"
log_message "  - Controls: $(wc -l < ${OUTPUT_DIR}/controls_list.txt)"

################################################################################
# Step 2: Basic Statistics (Pre-QC)
################################################################################
log_message "[Step 2/18] Generating basic statistics (pre-QC)..."

plink --bfile "$INPUT_PREFIX" \
      --freq \
      --missing \
      --hardy \
      --het \
      --out "${QC_DIR}/basic_stats_preQC" \
      --allow-no-sex || error_exit "Failed to generate basic statistics"

log_message "Pre-QC statistics generated"

################################################################################
# Step 3: Identify Individuals with High Missingness (First Pass)
################################################################################
log_message "[Step 3/18] Identifying individuals with high missingness..."

plink --bfile "$INPUT_PREFIX" \
      --missing \
      --out "${QC_DIR}/missingness_check" \
      --allow-no-sex

# Create list of individuals to remove (>MIND_THRESHOLD missing)
awk -v thresh=$MIND_THRESHOLD 'NR>1 && $6>thresh {print $1, $2}' \
    "${QC_DIR}/missingness_check.imiss" > "${QC_DIR}/high_miss_individuals.txt"

REMOVED_INDIV=$(wc -l < ${QC_DIR}/high_miss_individuals.txt)
log_message "Identified ${REMOVED_INDIV} individuals with >${MIND_THRESHOLD} missingness"

################################################################################
# Step 4: Quality Control - Sex Check and Discordance
################################################################################
log_message "[Step 4/18] Performing sex check..."

plink --bfile "$INPUT_PREFIX" \
      --check-sex \
      --out "${QC_DIR}/${INPUT_PREFIX}_sexcheck" \
      --allow-no-sex

# Identify sex discordant samples
awk '$5=="PROBLEM" {print $1, $2}' "${QC_DIR}/${INPUT_PREFIX}_sexcheck.sexcheck" \
    > "${QC_DIR}/sex_discordance.txt" 2>/dev/null || touch "${QC_DIR}/sex_discordance.txt"

SEX_DISCORD=$(wc -l < ${QC_DIR}/sex_discordance.txt)
log_message "Identified ${SEX_DISCORD} individuals with sex discordance"

################################################################################
# Step 5: Quality Control - Missing Data Filter
################################################################################
log_message "[Step 5/18] Quality Control - Missing data filters..."

# Filter SNPs with >GENO_THRESHOLD missing rate and individuals with >MIND_THRESHOLD missing rate
plink --bfile "$INPUT_PREFIX" \
      --geno $GENO_THRESHOLD \
      --mind $MIND_THRESHOLD \
      --make-bed \
      --out "${QC_DIR}/${INPUT_PREFIX}_qc1_missing" \
      --allow-no-sex || error_exit "Failed at missing data QC step"

log_message "Missing data QC completed"
log_message "  - Remaining individuals: $(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc1_missing.fam)"
log_message "  - Remaining SNPs: $(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc1_missing.bim)"

################################################################################
# Step 6: Quality Control - MAF Filter
################################################################################
log_message "[Step 6/18] Quality Control - Minor Allele Frequency filter..."

# Filter SNPs with MAF < MAF_THRESHOLD
plink --bfile "${QC_DIR}/${INPUT_PREFIX}_qc1_missing" \
      --maf $MAF_THRESHOLD \
      --make-bed \
      --out "${QC_DIR}/${INPUT_PREFIX}_qc2_maf" \
      --allow-no-sex || error_exit "Failed at MAF filter step"

log_message "MAF filter completed"
log_message "  - Remaining SNPs: $(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc2_maf.bim)"

################################################################################
# Step 7: Quality Control - Hardy-Weinberg Equilibrium
################################################################################
log_message "[Step 7/18] Quality Control - Hardy-Weinberg equilibrium test..."

# Filter SNPs that fail HWE test (p < HWE_THRESHOLD)
# More stringent in controls, less stringent in cases
plink --bfile "${QC_DIR}/${INPUT_PREFIX}_qc2_maf" \
      --hwe $HWE_THRESHOLD \
      --hwe-all \
      --make-bed \
      --out "${QC_DIR}/${INPUT_PREFIX}_qc3_hwe" \
      --allow-no-sex || error_exit "Failed at HWE filter step"

log_message "HWE filter completed"
log_message "  - Remaining SNPs: $(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc3_hwe.bim)"

################################################################################
# Step 8: Heterozygosity Check
################################################################################
log_message "[Step 8/18] Checking heterozygosity outliers..."

# First prune for LD
plink --bfile "${QC_DIR}/${INPUT_PREFIX}_qc3_hwe" \
      --indep-pairwise $LD_WINDOW $LD_STEP $LD_R2 \
      --out "${QC_DIR}/heterozygosity_pruning" \
      --allow-no-sex

# Calculate heterozygosity
plink --bfile "${QC_DIR}/${INPUT_PREFIX}_qc3_hwe" \
      --extract "${QC_DIR}/heterozygosity_pruning.prune.in" \
      --het \
      --out "${QC_DIR}/${INPUT_PREFIX}_heterozygosity" \
      --allow-no-sex

# Identify outliers (mean ± 3 SD)
awk 'NR>1 {print $1, $2, ($5-$3)/$5}' "${QC_DIR}/${INPUT_PREFIX}_heterozygosity.het" \
    > "${QC_DIR}/het_values.txt"

# Calculate mean and SD, then identify outliers
Rscript - <<EOF
data <- read.table("${QC_DIR}/het_values.txt", header=FALSE)
mean_het <- mean(data\$V3)
sd_het <- sd(data\$V3)
lower <- mean_het - 3*sd_het
upper <- mean_het + 3*sd_het
outliers <- data[data\$V3 < lower | data\$V3 > upper, 1:2]
write.table(outliers, "${QC_DIR}/het_outliers.txt", quote=FALSE, row.names=FALSE, col.names=FALSE)
cat("Mean heterozygosity:", mean_het, "\n")
cat("SD:", sd_het, "\n")
cat("Outliers:", nrow(outliers), "\n")
EOF

HET_OUTLIERS=$(wc -l < ${QC_DIR}/het_outliers.txt 2>/dev/null || echo "0")
log_message "Identified ${HET_OUTLIERS} heterozygosity outliers"

################################################################################
# Step 9: Generate Detailed QC Report
################################################################################
log_message "[Step 9/18] Generating detailed QC report..."

# Count samples and SNPs at each stage
{
    echo "================================================================================"
    echo "Quality Control Summary Report"
    echo "================================================================================"
    echo "Generated: $(date)"
    echo ""
    echo "QC Thresholds Applied:"
    echo "  - SNP missingness threshold: ${GENO_THRESHOLD}"
    echo "  - Individual missingness threshold: ${MIND_THRESHOLD}"
    echo "  - Minor Allele Frequency: ${MAF_THRESHOLD}"
    echo "  - Hardy-Weinberg Equilibrium: ${HWE_THRESHOLD}"
    echo ""
    echo "================================================================================"
    echo "SAMPLE QC SUMMARY"
    echo "================================================================================"
    echo ""
    echo "Original data:"
    printf "  Individuals: %d\n" "$(wc -l < ${INPUT_PREFIX}.fam)"
    printf "  Cases: %d\n" "$(awk '$6==2' ${INPUT_PREFIX}.fam | wc -l)"
    printf "  Controls: %d\n" "$(awk '$6==1' ${INPUT_PREFIX}.fam | wc -l)"
    printf "  Males: %d\n" "$(awk '$5==1' ${INPUT_PREFIX}.fam | wc -l)"
    printf "  Females: %d\n" "$(awk '$5==2' ${INPUT_PREFIX}.fam | wc -l)"
    printf "  Unknown sex: %d\n" "$(awk '$5==0' ${INPUT_PREFIX}.fam | wc -l)"
    echo ""
    echo "After missing data filter (--geno ${GENO_THRESHOLD} --mind ${MIND_THRESHOLD}):"
    printf "  Individuals: %d\n" "$(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc1_missing.fam)"
    printf "  Individuals removed: %d\n" $(($(wc -l < ${INPUT_PREFIX}.fam) - $(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc1_missing.fam)))
    echo ""
    echo "QC Flags:"
    printf "  Sex discordance: %d\n" "${SEX_DISCORD}"
    printf "  Heterozygosity outliers: %d\n" "${HET_OUTLIERS}"
    echo ""
    echo "================================================================================"
    echo "SNP QC SUMMARY"
    echo "================================================================================"
    echo ""
    echo "Original data:"
    printf "  SNPs: %d\n" "$(wc -l < ${INPUT_PREFIX}.bim)"
    echo ""
    echo "After missing data filter (--geno ${GENO_THRESHOLD}):"
    printf "  SNPs: %d\n" "$(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc1_missing.bim)"
    printf "  SNPs removed: %d\n" $(($(wc -l < ${INPUT_PREFIX}.bim) - $(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc1_missing.bim)))
    echo ""
    echo "After MAF filter (--maf ${MAF_THRESHOLD}):"
    printf "  SNPs: %d\n" "$(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc2_maf.bim)"
    printf "  SNPs removed: %d\n" $(($(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc1_missing.bim) - $(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc2_maf.bim)))
    echo ""
    echo "After HWE filter (--hwe ${HWE_THRESHOLD}):"
    printf "  SNPs: %d\n" "$(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc3_hwe.bim)"
    printf "  SNPs removed: %d\n" $(($(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc2_maf.bim) - $(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc3_hwe.bim)))
    echo ""
    echo "================================================================================"
    echo "TOTAL FILTERING SUMMARY"
    echo "================================================================================"
    printf "  Total individuals removed: %d (%.2f%%)\n" \
        $(("$(wc -l < ${INPUT_PREFIX}.fam)" - "$(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc3_hwe.fam)")) \
        "$(awk -v orig="$(wc -l < ${INPUT_PREFIX}.fam)" -v final="$(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc3_hwe.fam)" 'BEGIN {print (orig-final)/orig*100}')"
    printf "  Total SNPs removed: %d (%.2f%%)\n" \
        $(("$(wc -l < ${INPUT_PREFIX}.bim)" - "$(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc3_hwe.bim)")) \
        "$(awk -v orig="$(wc -l < ${INPUT_PREFIX}.bim)" -v final="$(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc3_hwe.bim)" 'BEGIN {print (orig-final)/orig*100}')"
    echo "================================================================================"
} > "${QC_DIR}/qc_summary.txt"

cat "${QC_DIR}/qc_summary.txt"
log_message "QC summary saved to ${QC_DIR}/qc_summary.txt"

################################################################################
# Step 10: Population Stratification - LD Pruning for PCA
################################################################################
log_message "[Step 10/18] LD pruning for population stratification analysis..."

plink --bfile "${QC_DIR}/${INPUT_PREFIX}_qc3_hwe" \
      --indep-pairwise $LD_WINDOW $LD_STEP $LD_R2 \
      --out "${QC_DIR}/${INPUT_PREFIX}_pruning" \
      --allow-no-sex || error_exit "Failed at LD pruning step"

# Extract pruned SNPs
plink --bfile "${QC_DIR}/${INPUT_PREFIX}_qc3_hwe" \
      --extract "${QC_DIR}/${INPUT_PREFIX}_pruning.prune.in" \
      --make-bed \
      --out "${QC_DIR}/${INPUT_PREFIX}_pruned" \
      --allow-no-sex || error_exit "Failed to extract pruned SNPs"

log_message "LD pruning completed"
log_message "  - Pruned SNPs: $(wc -l < ${QC_DIR}/${INPUT_PREFIX}_pruning.prune.in)"

################################################################################
# Step 11: Principal Component Analysis
################################################################################
log_message "[Step 11/18] Running Principal Component Analysis..."

plink --bfile "${QC_DIR}/${INPUT_PREFIX}_pruned" \
      --pca 20 header tabs \
      --out "${QC_DIR}/${INPUT_PREFIX}_pca" \
      --allow-no-sex || error_exit "Failed at PCA step"

log_message "PCA completed - 20 principal components calculated"

################################################################################
# Step 12: Relatedness Check (IBD/Kinship)
################################################################################
log_message "[Step 12/18] Checking for relatedness (IBD)..."

plink --bfile "${QC_DIR}/${INPUT_PREFIX}_pruned" \
      --genome \
      --min 0.05 \
      --out "${QC_DIR}/${INPUT_PREFIX}_ibd" \
      --allow-no-sex || error_exit "Failed at IBD calculation"

# Identify related individuals (PI_HAT > IBD_THRESHOLD)
awk -v thresh=$IBD_THRESHOLD '$10 > thresh {print $0}' \
    "${QC_DIR}/${INPUT_PREFIX}_ibd.genome" > "${QC_DIR}/related_pairs.txt" 2>/dev/null || touch "${QC_DIR}/related_pairs.txt"

RELATED_PAIRS=$(wc -l < ${QC_DIR}/related_pairs.txt)
log_message "Identified ${RELATED_PAIRS} related pairs (PI_HAT > ${IBD_THRESHOLD})"

# Create list of one individual from each related pair to remove
if [ "$RELATED_PAIRS" -gt 0 ]; then
    awk -v thresh=$IBD_THRESHOLD '$10 > thresh {print $1, $2}' \
        "${QC_DIR}/${INPUT_PREFIX}_ibd.genome" | head -n 1 > "${QC_DIR}/related_to_remove.txt"
    log_message "Created list of related individuals to consider removing"
fi

################################################################################
# Step 13: Association Analysis - Basic Case-Control
################################################################################
log_message "[Step 13/18] Running association analyses..."

# Association WITHOUT QC (using original data)
log_message "  - Running association test on ORIGINAL data (no QC)..."
plink --bfile "$INPUT_PREFIX" \
      --assoc \
      --adjust \
      --ci 0.95 \
      --out "${ASSOC_DIR}/${INPUT_PREFIX}_assoc_noQC" \
      --allow-no-sex || log_message "  Warning: No-QC association test failed"

plink --bfile "$INPUT_PREFIX" \
      --logistic \
      --ci 0.95 \
      --out "${ASSOC_DIR}/${INPUT_PREFIX}_logistic_noQC" \
      --allow-no-sex || log_message "  Warning: No-QC logistic regression failed"

# Association WITH QC (using QC-filtered data)
log_message "  - Running association test on QC-FILTERED data..."
plink --bfile "${QC_DIR}/${INPUT_PREFIX}_qc3_hwe" \
      --assoc \
      --adjust \
      --ci 0.95 \
      --out "${ASSOC_DIR}/${INPUT_PREFIX}_assoc_withQC" \
      --allow-no-sex || error_exit "Failed at QC-filtered association test"

# Logistic regression (binary phenotype)
log_message "  - Running logistic regression (QC-filtered)..."
plink --bfile "${QC_DIR}/${INPUT_PREFIX}_qc3_hwe" \
      --logistic \
      --ci 0.95 \
      --out "${ASSOC_DIR}/${INPUT_PREFIX}_logistic_withQC" \
      --allow-no-sex || error_exit "Failed at QC-filtered logistic regression"

# Linear regression (for quantitative traits if applicable)
log_message "  - Running linear regression (QC-filtered)..."
plink --bfile "${QC_DIR}/${INPUT_PREFIX}_qc3_hwe" \
      --linear \
      --ci 0.95 \
      --out "${ASSOC_DIR}/${INPUT_PREFIX}_linear" \
      --allow-no-sex 2>/dev/null || log_message "  Note: Linear regression skipped (likely binary phenotype)"

# Also keep original naming for backward compatibility
log_message "  - Creating standard output files..."
cp "${ASSOC_DIR}/${INPUT_PREFIX}_assoc_withQC.assoc" "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" 2>/dev/null || true
cp "${ASSOC_DIR}/${INPUT_PREFIX}_logistic_withQC.assoc.logistic" "${ASSOC_DIR}/${INPUT_PREFIX}_logistic.assoc.logistic" 2>/dev/null || true

################################################################################
# Step 14: Association with Covariates (PCA adjustment)
################################################################################
log_message "[Step 14/18] Running association analysis with PCA covariates..."

# Extract first 10 PCs as covariates (skip header)
tail -n +2 "${QC_DIR}/${INPUT_PREFIX}_pca.eigenvec" | \
    awk '{print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12}' \
    > "${QC_DIR}/pca_covariates_10PCs.txt"

# Logistic regression with PCA covariates
log_message "  - Logistic regression with 10 PCs..."
plink --bfile "${QC_DIR}/${INPUT_PREFIX}_qc3_hwe" \
      --logistic \
      --covar "${QC_DIR}/pca_covariates_10PCs.txt" \
      --hide-covar \
      --ci 0.95 \
      --out "${ASSOC_DIR}/${INPUT_PREFIX}_logistic_10PCs" \
      --allow-no-sex || log_message "  Warning: PCA-adjusted logistic regression failed"

# Also run with first 3 PCs only
tail -n +2 "${QC_DIR}/${INPUT_PREFIX}_pca.eigenvec" | \
    awk '{print $1, $2, $3, $4, $5}' \
    > "${QC_DIR}/pca_covariates_3PCs.txt"

log_message "  - Logistic regression with 3 PCs..."
plink --bfile "${QC_DIR}/${INPUT_PREFIX}_qc3_hwe" \
      --logistic \
      --covar "${QC_DIR}/pca_covariates_3PCs.txt" \
      --hide-covar \
      --ci 0.95 \
      --out "${ASSOC_DIR}/${INPUT_PREFIX}_logistic_3PCs" \
      --allow-no-sex || log_message "  Warning: PCA-adjusted logistic regression (3PC) failed"

################################################################################
# Step 15: Generate Top Hits and Significant SNPs
################################################################################
log_message "[Step 15/18] Extracting top associated SNPs..."

# Check if association file exists and has results
if [ -f "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" ]; then
    log_message "  - Extracting top SNPs (using efficient method)..."
    
    # Try Python method first (much faster for large files)
    if command -v python3 &> /dev/null; then
        python3 extract_top_snps.py \
            "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" \
            "${ASSOC_DIR}" 2>/dev/null && log_message "  - Python extraction successful" || {
            log_message "  - Python method failed, using awk-based extraction..."
            
            # Fallback: Use awk to extract SNPs with valid p-values and sort top results
            awk 'NR==1 {print; next} $9 != "NA" && $9 != "" {print | "sort -k9,9g | head -n 1000"}' \
                "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" > "${ASSOC_DIR}/top_1000_snps.txt" 2>/dev/null || {
                # Last resort: just get first 1000 lines with valid p-values
                awk 'NR==1 || ($9 != "NA" && $9 != "")' "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" | \
                    head -n 1001 > "${ASSOC_DIR}/top_1000_snps.txt"
            }
            
            # Top 100 SNPs
            head -n 101 "${ASSOC_DIR}/top_1000_snps.txt" > "${ASSOC_DIR}/top_100_snps.txt"
            
            # Extract genome-wide significant SNPs (p < 5e-8)
            awk 'NR==1 || ($9 != "NA" && $9 < 5e-8)' "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" \
                > "${ASSOC_DIR}/genome_wide_significant_snps_5e-8.txt"
            
            # Extract suggestive SNPs (p < 1e-5)
            awk 'NR==1 || ($9 != "NA" && $9 < 1e-5)' "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" \
                > "${ASSOC_DIR}/suggestive_snps_1e-5.txt"
        }
    else
        log_message "  - Python not available, using awk extraction..."
        # Direct awk method without heavy sorting
        awk 'NR==1 || ($9 != "NA" && $9 < 1e-5)' "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" \
            > "${ASSOC_DIR}/suggestive_snps_1e-5.txt"
        
        awk 'NR==1 || ($9 != "NA" && $9 < 5e-8)' "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" \
            > "${ASSOC_DIR}/genome_wide_significant_snps_5e-8.txt"
        
        head -n 1001 "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" > "${ASSOC_DIR}/top_1000_snps.txt"
        head -n 101 "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" > "${ASSOC_DIR}/top_100_snps.txt"
    fi
    
    GW_SIG=$(tail -n +2 "${ASSOC_DIR}/genome_wide_significant_snps_5e-8.txt" | wc -l)
    SUGG=$(tail -n +2 "${ASSOC_DIR}/suggestive_snps_1e-5.txt" | wc -l)
    
    log_message "Significant SNPs identified:"
    log_message "  - Genome-wide significant (p < 5e-8): ${GW_SIG}"
    log_message "  - Suggestive (p < 1e-5): ${SUGG}"
    log_message "  - Top 100 SNPs saved"
    log_message "  - Top 1000 SNPs saved"
fi

# Extract significant SNPs from PCA-adjusted results if available
if [ -f "${ASSOC_DIR}/${INPUT_PREFIX}_logistic_3PCs.assoc.logistic" ]; then
    awk 'NR==1 || ($5=="ADD" && $9 != "NA" && $9 < 5e-8)' \
        "${ASSOC_DIR}/${INPUT_PREFIX}_logistic_3PCs.assoc.logistic" \
        > "${ASSOC_DIR}/genome_wide_significant_snps_3PCs.txt" 2>/dev/null || true
    
    if [ -f "${ASSOC_DIR}/genome_wide_significant_snps_3PCs.txt" ]; then
        GW_SIG_PCA=$(tail -n +2 "${ASSOC_DIR}/genome_wide_significant_snps_3PCs.txt" 2>/dev/null | wc -l || echo "0")
        log_message "  - Genome-wide significant with 3 PCs: ${GW_SIG_PCA}"
    fi
fi

################################################################################
# Step 16: Export Results in Different Formats
################################################################################
log_message "[Step 16/18] Exporting results in various formats..."

# Convert to VCF format
log_message "  - Exporting to VCF format..."
plink --bfile "${QC_DIR}/${INPUT_PREFIX}_qc3_hwe" \
      --recode vcf bgz \
      --out "${OUTPUT_DIR}/${INPUT_PREFIX}_qc_filtered" \
      --allow-no-sex || log_message "  Warning: VCF export failed"

# Export as text format (PED/MAP)
log_message "  - Exporting to PED/MAP format..."
plink --bfile "${QC_DIR}/${INPUT_PREFIX}_qc3_hwe" \
      --recode \
      --out "${OUTPUT_DIR}/${INPUT_PREFIX}_qc_filtered" \
      --allow-no-sex || log_message "  Warning: PED/MAP export failed"

# Export as transposed format (TPED/TFAM) - useful for some analyses
log_message "  - Exporting to TPED/TFAM format..."
plink --bfile "${QC_DIR}/${INPUT_PREFIX}_qc3_hwe" \
      --recode transpose \
      --out "${OUTPUT_DIR}/${INPUT_PREFIX}_qc_filtered" \
      --allow-no-sex || log_message "  Warning: TPED/TFAM export failed"

# Create a summary statistics file from association results
if [ -f "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" ]; then
    log_message "  - Creating summary statistics file..."
    {
        echo -e "CHR\tSNP\tBP\tA1\tA2\tMAF\tOR\tP"
        tail -n +2 "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" | \
        awk '{
            if ($9 != "NA") {
                or = exp($7);  # Convert log odds to OR (approximation for small effects)
                print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"or"\t"$9
            }
        }'
    } > "${ASSOC_DIR}/summary_statistics.txt"
fi

log_message "Export completed"

################################################################################
# Step 17: Generate Plots and Visualizations
################################################################################
log_message "[Step 17/18] Generating plots and visualizations..."

# Check if Python with required libraries is available
if command -v python3 &> /dev/null; then
    log_message "  - Attempting to create visualization plots..."
    
    python3 generate_plots.py \
        "${ASSOC_DIR}" \
        "${QC_DIR}" \
        "${PLOTS_DIR}" 2>&1 | while IFS= read -r line; do log_message "    $line"; done || \
        log_message "  Note: Plotting failed - may need matplotlib/pandas/seaborn installed"
    
    log_message "  - Plots saved to ${PLOTS_DIR}/"
else
    log_message "  Note: Python3 not available - skipping visualization plots"
    log_message "  To generate plots manually, run:"
    log_message "    python3 generate_plots.py ${ASSOC_DIR} ${QC_DIR} ${PLOTS_DIR}"
fi

################################################################################
# Step 18: Generate Final Summary Report
################################################################################
log_message "[Step 18/18] Generating final comprehensive summary report..."

FINAL_INDIV=$(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc3_hwe.fam)
FINAL_SNPS=$(wc -l < ${QC_DIR}/${INPUT_PREFIX}_qc3_hwe.bim)
ORIG_INDIV=$(wc -l < ${INPUT_PREFIX}.fam)
ORIG_SNPS=$(wc -l < ${INPUT_PREFIX}.bim)

cat > "${REPORT_DIR}/GWAS_Analysis_Final_Report.txt" << EOF
================================================================================
                    GWAS ANALYSIS PIPELINE - FINAL REPORT
================================================================================
Analysis Date: $(date)
Input Dataset: ${INPUT_PREFIX}
Working Directory: ${WORKDIR}
PLINK Version: $(plink --version 2>&1 | head -n 1 || echo "PLINK 1.9")

================================================================================
                           SAMPLE INFORMATION
================================================================================

Original Dataset:
  Total Individuals:        ${ORIG_INDIV}
  Cases (affected):         $(awk '$6==2' ${INPUT_PREFIX}.fam | wc -l)
  Controls (unaffected):    $(awk '$6==1' ${INPUT_PREFIX}.fam | wc -l)
  Unknown phenotype:        $(awk '$6==-9 || $6==0' ${INPUT_PREFIX}.fam | wc -l)
  Males:                    $(awk '$5==1' ${INPUT_PREFIX}.fam | wc -l)
  Females:                  $(awk '$5==2' ${INPUT_PREFIX}.fam | wc -l)
  Unknown sex:              $(awk '$5==0' ${INPUT_PREFIX}.fam | wc -l)

After Quality Control:
  Total Individuals:        ${FINAL_INDIV}
  Cases (affected):         $(awk '$6==2' ${QC_DIR}/${INPUT_PREFIX}_qc3_hwe.fam | wc -l)
  Controls (unaffected):    $(awk '$6==1' ${QC_DIR}/${INPUT_PREFIX}_qc3_hwe.fam | wc -l)
  
Individuals Removed:        $((ORIG_INDIV - FINAL_INDIV)) ($(awk -v o="$ORIG_INDIV" -v f="$FINAL_INDIV" 'BEGIN {printf "%.2f", (o-f)/o*100}')%)

================================================================================
                            SNP INFORMATION
================================================================================

Original Dataset:
  Total SNPs:               ${ORIG_SNPS}

After Quality Control:
  Total SNPs:               ${FINAL_SNPS}
  
SNPs Removed:               $((ORIG_SNPS - FINAL_SNPS)) ($(awk -v o="$ORIG_SNPS" -v f="$FINAL_SNPS" 'BEGIN {printf "%.2f", (o-f)/o*100}')%)
SNPs for PCA (LD-pruned):   $(wc -l < ${QC_DIR}/${INPUT_PREFIX}_pruning.prune.in)

================================================================================
                      QUALITY CONTROL FILTERS APPLIED
================================================================================

SNP-level filters:
  - SNP missingness:                    > ${GENO_THRESHOLD} ($(awk -v t=$GENO_THRESHOLD 'BEGIN {printf "%.1f%%", t*100}'))
  - Minor Allele Frequency:             < ${MAF_THRESHOLD}
  - Hardy-Weinberg Equilibrium p-value: < ${HWE_THRESHOLD}

Individual-level filters:
  - Individual missingness:             > ${MIND_THRESHOLD} ($(awk -v t=$MIND_THRESHOLD 'BEGIN {printf "%.1f%%", t*100}'))
  
LD Pruning parameters:
  - Window size:                        ${LD_WINDOW} SNPs
  - Step size:                          ${LD_STEP} SNPs
  - r² threshold:                       ${LD_R2}

================================================================================
                         QUALITY CONTROL FLAGS
================================================================================

Sex discordance:            ${SEX_DISCORD} individuals
Heterozygosity outliers:    ${HET_OUTLIERS} individuals
Related pairs (PI_HAT>${IBD_THRESHOLD}):  ${RELATED_PAIRS} pairs

================================================================================
                        ASSOCIATION RESULTS SUMMARY
================================================================================
EOF

# Add association results if available
if [ -f "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" ]; then
    cat >> "${REPORT_DIR}/GWAS_Analysis_Final_Report.txt" << EOF

Basic Association Test:
  Genome-wide significant SNPs (p < 5e-8):   ${GW_SIG:-0}
  Suggestive SNPs (p < 1e-5):                ${SUGG:-0}
  
Top SNP: $(tail -n +2 "${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc" | sort -k9 -g | head -n 1 | awk '{print $2" (Chr"$1":"$3", p="$9")"}' || echo "N/A")

Association Results with PCA Adjustment:
  Logistic regression with 3 PCs:   Available
  Logistic regression with 10 PCs:  Available

EOF
fi

cat >> "${REPORT_DIR}/GWAS_Analysis_Final_Report.txt" << EOF
================================================================================
                           OUTPUT FILES SUMMARY
================================================================================

Individual Lists:
  ${OUTPUT_DIR}/individuals_detailed.txt          - All individuals with full info
  ${OUTPUT_DIR}/individuals_id_only.txt           - FID and IID only
  ${OUTPUT_DIR}/cases_list.txt                    - Case individuals
  ${OUTPUT_DIR}/controls_list.txt                 - Control individuals

Quality Control Files:
  ${QC_DIR}/qc_summary.txt                        - Detailed QC summary
  ${QC_DIR}/basic_stats_preQC.*                   - Pre-QC statistics
  ${QC_DIR}/${INPUT_PREFIX}_sexcheck.sexcheck     - Sex check results
  ${QC_DIR}/sex_discordance.txt                   - Sex discordant samples
  ${QC_DIR}/het_outliers.txt                      - Heterozygosity outliers
  ${QC_DIR}/related_pairs.txt                     - Related sample pairs

Clean Genotype Data:
  ${QC_DIR}/${INPUT_PREFIX}_qc3_hwe.{bed,bim,fam} - QC-filtered binary files

Population Structure:
  ${QC_DIR}/${INPUT_PREFIX}_pca.eigenvec          - Principal components
  ${QC_DIR}/${INPUT_PREFIX}_pca.eigenval          - Eigenvalues
  ${QC_DIR}/${INPUT_PREFIX}_ibd.genome            - IBD/relatedness estimates

Association Results:
  ${ASSOC_DIR}/${INPUT_PREFIX}_assoc.assoc        - Basic association test
  ${ASSOC_DIR}/${INPUT_PREFIX}_logistic.*         - Logistic regression results
  ${ASSOC_DIR}/${INPUT_PREFIX}_logistic_3PCs.*    - With 3 PC covariates
  ${ASSOC_DIR}/${INPUT_PREFIX}_logistic_10PCs.*   - With 10 PC covariates
  ${ASSOC_DIR}/top_100_snps.txt                   - Top 100 associated SNPs
  ${ASSOC_DIR}/top_1000_snps.txt                  - Top 1000 associated SNPs
  ${ASSOC_DIR}/genome_wide_significant_snps_5e-8.txt  - Significant SNPs
  ${ASSOC_DIR}/suggestive_snps_1e-5.txt           - Suggestive SNPs
  ${ASSOC_DIR}/summary_statistics.txt             - Summary stats for downstream tools

Exported Formats:
  ${OUTPUT_DIR}/${INPUT_PREFIX}_qc_filtered.vcf.gz    - VCF format
  ${OUTPUT_DIR}/${INPUT_PREFIX}_qc_filtered.{ped,map} - PED/MAP format
  ${OUTPUT_DIR}/${INPUT_PREFIX}_qc_filtered.{tped,tfam} - TPED/TFAM format

================================================================================
                          NEXT STEPS & RECOMMENDATIONS
================================================================================

1. Review QC flags:
   - Check sex_discordance.txt for samples with sex inconsistencies
   - Review het_outliers.txt for potential contamination or sample issues
   - Examine related_pairs.txt and consider removing one from each pair

2. Visualize results:
   - Create Manhattan plots for association results
   - Generate Q-Q plots to assess genomic inflation
   - Plot PC1 vs PC2 to check for population stratification

3. Downstream analyses:
   - Perform conditional analysis on top hits
   - Calculate genomic inflation factor (λ)
   - Annotate significant SNPs with gene information
   - Perform gene-set enrichment analysis

4. Replication:
   - Test top hits in independent cohorts
   - Meta-analysis with other GWAS datasets

5. Functional follow-up:
   - eQTL analysis for significant SNPs
   - Pathway and network analysis
   - Fine-mapping of associated regions

================================================================================
                              PIPELINE STATUS
================================================================================

Pipeline completed successfully at: $(date)
Total runtime: Approximately \$((SECONDS/60)) minutes

For questions or issues, contact: muhammad.muzammal@bs.qau.edu.pk

================================================================================
                                  END OF REPORT
================================================================================
EOF

cat "${REPORT_DIR}/GWAS_Analysis_Final_Report.txt"

# Copy important summary to main output directory
cp "${REPORT_DIR}/GWAS_Analysis_Final_Report.txt" "${OUTPUT_DIR}/pipeline_summary.txt"

log_message ""
log_message "========================================="
log_message "Pipeline completed successfully!"
log_message "========================================="
log_message "Results Summary:"
log_message "  - Individuals (pre-QC):  ${ORIG_INDIV}"
log_message "  - Individuals (post-QC): ${FINAL_INDIV}"
log_message "  - SNPs (pre-QC):         ${ORIG_SNPS}"
log_message "  - SNPs (post-QC):        ${FINAL_SNPS}"
log_message "  - Significant SNPs:      ${GW_SIG:-0} (p < 5e-8)"
log_message ""
log_message "All results saved in: ${OUTPUT_DIR}/"
log_message "Final report: ${REPORT_DIR}/GWAS_Analysis_Final_Report.txt"
log_message "========================================="
log_message "Analysis completed at: $(date)"
log_message "========================================="
