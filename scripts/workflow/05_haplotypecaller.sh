#!/bin/bash
#SBATCH --job-name=trio_hc
#SBATCH --partition=short
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=12:00:00
#SBATCH --output=%x_%j.out

set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"

REF="$PROJECT/reference/GCF_000001405.40_GRCh38.p14_genomic.fna"
BED="$PROJECT/reference/S07604514_Covered_NCBI_GRCh38_merged.bed"
GATK="$PROJECT/containers/gatk_4.6.2.0.sif"

mkdir -p "$PROJECT/variants/gvcf"

for SAMPLE in PROBAND MOTHER FATHER
do
    echo "Processing $SAMPLE"

    apptainer exec --bind "$PROJECT:$PROJECT" "$GATK" \
        gatk --java-options "-Xmx16g" HaplotypeCaller \
        -R "$REF" \
        -I "$PROJECT/bam/recalibrated/${SAMPLE}.recal.bam" \
        -L "$BED" \
        -ERC GVCF \
        -O "$PROJECT/variants/gvcf/${SAMPLE}.g.vcf.gz"

    echo "Completed $SAMPLE"
done

echo "ALL THREE SAMPLES COMPLETED"
