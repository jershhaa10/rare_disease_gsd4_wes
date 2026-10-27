#!/bin/bash
#SBATCH --job-name=trio_normalize
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=trio_normalize_%j.out
#SBATCH --error=trio_normalize_%j.err

set -euo pipefail

module load bcftools/1.21

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"

REF="$PROJECT/reference/GCF_000001405.40_GRCh38.p14_genomic.fna"
INPUT="$PROJECT/variants/joint_genotyping/TRIO.joint.vcf.gz"
OUTPUT="$PROJECT/variants/filtered/TRIO.normalized.vcf.gz"

echo "Starting VCF normalization..."

bcftools norm \
    -f "$REF" \
    -m -any \
    -c e \
    -Oz \
    -o "$OUTPUT" \
    "$INPUT"

echo "Indexing normalized VCF..."
bcftools index -t "$OUTPUT"

echo "=== Original record count ==="
bcftools view -H "$INPUT" | wc -l

echo "=== Normalized record count ==="
bcftools view -H "$OUTPUT" | wc -l

echo "=== Normalized variant statistics ==="
bcftools stats "$OUTPUT" | grep '^SN'

echo "Normalization completed successfully."
