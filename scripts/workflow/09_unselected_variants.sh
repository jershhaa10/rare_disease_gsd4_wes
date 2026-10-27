#!/bin/bash
#SBATCH --job-name=unselected_variants
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=unselected_%j.out
#SBATCH --error=unselected_%j.err

set -euo pipefail

module load bcftools/1.21

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
ORIGINAL="$PROJECT/variants/joint_genotyping/TRIO.joint.vcf.gz"
SNPS="$PROJECT/variants/filtered/TRIO.snps.vcf.gz"
INDELS="$PROJECT/variants/filtered/TRIO.indels.vcf.gz"
OUTPUT="$PROJECT/variants/filtered/TRIO.unselected.vcf.gz"

echo "Extracting unselected variants..."

bcftools isec -C -w1 -c none \
    "$ORIGINAL" \
    "$SNPS" \
    "$INDELS" \
    -Oz -o "$OUTPUT"

bcftools index -t "$OUTPUT"

echo "=== Number of unselected records ==="
bcftools view -H "$OUTPUT" | wc -l

echo "=== First 10 unselected variants ==="
bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\n' "$OUTPUT" | head -n 10

echo "Extraction completed."
