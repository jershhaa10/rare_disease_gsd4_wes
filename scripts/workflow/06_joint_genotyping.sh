#!/bin/bash
#SBATCH --job-name=trio_joint
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=08:00:00
#SBATCH --output=trio_joint_%j.out
#SBATCH --error=trio_joint_%j.err

set -euo pipefail

# Project directory
PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"

# Reference genome
REF="$PROJECT/reference/GCF_000001405.40_GRCh38.p14_genomic.fna"

# Target regions
BED="$PROJECT/reference/S07604514_Covered_NCBI_GRCh38_merged.bed"

# GATK container
GATK="$PROJECT/containers/gatk_4.6.2.0.sif"

# Input GVCFs
PROBAND="$PROJECT/variants/gvcf/PROBAND.g.vcf.gz"
MOTHER="$PROJECT/variants/gvcf/MOTHER.g.vcf.gz"
FATHER="$PROJECT/variants/gvcf/FATHER.g.vcf.gz"

# Output directory
OUTPUT="$PROJECT/variants/joint_genotyping"

mkdir -p "$OUTPUT"

# Step 1: Combine individual GVCFs
echo "Starting CombineGVCFs..."

apptainer exec --bind "$PROJECT:$PROJECT" "$GATK" \
    gatk --java-options "-Xmx16g" CombineGVCFs \
    -R "$REF" \
    -V "$PROBAND" \
    -V "$MOTHER" \
    -V "$FATHER" \
    -L "$BED" \
    -O "$OUTPUT/TRIO.combined.g.vcf.gz"

echo "CombineGVCFs completed."

# Step 2: Joint genotyping
echo "Starting GenotypeGVCFs..."

apptainer exec --bind "$PROJECT:$PROJECT" "$GATK" \
    gatk --java-options "-Xmx16g" GenotypeGVCFs \
    -R "$REF" \
    -V "$OUTPUT/TRIO.combined.g.vcf.gz" \
    -L "$BED" \
    -O "$OUTPUT/TRIO.joint.vcf.gz"

echo "Joint genotyping was successfully finished."
