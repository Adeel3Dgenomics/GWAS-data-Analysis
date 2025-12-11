#!/bin/bash
################################################################################
# Simple script to extract individual lists from PLINK files
# Author: Adeel
# Date: December 11, 2025
################################################################################

# Load PLINK module
ml plink2/1.90b3w

# Set working directory
WORKDIR="/s/nath-lab/adeel/AA-GWAS/AA_GWAS"
cd "$WORKDIR"

# Input file prefix
INPUT_PREFIX="AA_GWAS_hg19_uniq"
OUTPUT_DIR="individuals_lists"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "=========================================="
echo "Extracting Individual Lists"
echo "Input: ${INPUT_PREFIX}"
echo "=========================================="

# Extract individual lists directly from FAM file
echo "Extracting from FAM file..."

# Create detailed individual file with headers
echo -e "FID\tIID\tFather_ID\tMother_ID\tSex\tPhenotype" > "${OUTPUT_DIR}/individuals_detailed.txt"
awk '{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6}' ${INPUT_PREFIX}.fam >> "${OUTPUT_DIR}/individuals_detailed.txt"

# Create simple ID list (FID IID only)
echo -e "FID\tIID" > "${OUTPUT_DIR}/individuals_id_only.txt"
awk '{print $1"\t"$2}' ${INPUT_PREFIX}.fam >> "${OUTPUT_DIR}/individuals_id_only.txt"

# Create case list
echo -e "FID\tIID" > "${OUTPUT_DIR}/cases_list.txt"
awk '$6==2 {print $1"\t"$2}' ${INPUT_PREFIX}.fam >> "${OUTPUT_DIR}/cases_list.txt"

# Create control list
echo -e "FID\tIID" > "${OUTPUT_DIR}/controls_list.txt"
awk '$6==1 {print $1"\t"$2}' ${INPUT_PREFIX}.fam >> "${OUTPUT_DIR}/controls_list.txt"

# Create male list
echo -e "FID\tIID" > "${OUTPUT_DIR}/males_list.txt"
awk '$5==1 {print $1"\t"$2}' ${INPUT_PREFIX}.fam >> "${OUTPUT_DIR}/males_list.txt"

# Create female list
echo -e "FID\tIID" > "${OUTPUT_DIR}/females_list.txt"
awk '$5==2 {print $1"\t"$2}' ${INPUT_PREFIX}.fam >> "${OUTPUT_DIR}/females_list.txt"

# Generate summary
cat > "${OUTPUT_DIR}/individuals_summary.txt" << EOF
================================================================================
Individual Lists Summary
================================================================================
Date: $(date)
Input Dataset: ${INPUT_PREFIX}

SAMPLE COUNTS:
- Total Individuals:    $(tail -n +2 ${OUTPUT_DIR}/individuals_id_only.txt | wc -l)
- Cases (affected):     $(tail -n +2 ${OUTPUT_DIR}/cases_list.txt | wc -l)
- Controls:             $(tail -n +2 ${OUTPUT_DIR}/controls_list.txt | wc -l)
- Males:                $(tail -n +2 ${OUTPUT_DIR}/males_list.txt | wc -l)
- Females:              $(tail -n +2 ${OUTPUT_DIR}/females_list.txt | wc -l)
- Unknown sex:          $(awk '$5==0' ${INPUT_PREFIX}.fam | wc -l)
- Unknown phenotype:    $(awk '$6==-9 || $6==0' ${INPUT_PREFIX}.fam | wc -l)

OUTPUT FILES:
- individuals_detailed.txt   : All fields from FAM file with headers
- individuals_id_only.txt    : FID and IID only
- cases_list.txt             : Cases/affected individuals
- controls_list.txt          : Control/unaffected individuals
- males_list.txt             : Male individuals
- females_list.txt           : Female individuals

FAM FILE FORMAT (6 columns):
1. FID        - Family ID
2. IID        - Individual ID
3. Father_ID  - Paternal ID (0 if unknown)
4. Mother_ID  - Maternal ID (0 if unknown)
5. Sex        - Sex (1=male, 2=female, 0=unknown)
6. Phenotype  - Phenotype (1=control, 2=case, -9/0=missing)

================================================================================
EOF

cat "${OUTPUT_DIR}/individuals_summary.txt"

echo ""
echo "========================================="
echo "Extraction completed!"
echo "Results saved in: ${OUTPUT_DIR}/"
echo "========================================="
