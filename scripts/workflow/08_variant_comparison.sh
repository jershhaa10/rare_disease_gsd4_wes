#!/bin/bash
#SBATCH --job-name=variant_compare
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=variant_compare_%j.out
#SBATCH --error=variant_compare_%j.err

set -euo pipefail

module load bcftools/1.21

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"

ORIGINAL="$PROJECT/variants/joint_genotyping/TRIO.joint.vcf.gz"
SNPS="$PROJECT/variants/filtered/TRIO.snps.vcf.gz"
INDELS="$PROJECT/variants/filtered/TRIO.indels.vcf.gz"

echo "=== Original variant records ==="
bcftools view -H "$ORIGINAL" | wc -l

echo "=== Selected SNP records ==="
bcftools view -H "$SNPS" | wc -l

echo "=== Selected indel records ==="
bcftools view -H "$INDELS" | wc -l

echo "=== Records missing from BOTH selected files ==="
bcftools isec -C -w1 -c none "$ORIGINAL" "$SNPS" "$INDELS" | \
    bcftools view -H | wc -l

echo "=== Records present in BOTH selected files ==="
bcftools isec -n=2 -w1 -c none "$SNPS" "$INDELS" | \
    bcftools view -H | wc -l

echo "=== Comparison completed ==="
