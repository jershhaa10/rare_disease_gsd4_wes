#!/bin/bash
#SBATCH --job-name=trio_bqsr
#SBATCH --partition=short
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=%x_%j.out

set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
REF="$PROJECT/reference/GCF_000001405.40_GRCh38.p14_genomic.fna"
DBSNP="$PROJECT/reference/Homo_sapiens_assembly38.dbsnp138.NCBI_GRCh38.vcf.gz"
MILLS="$PROJECT/reference/Mills_and_1000G_gold_standard.indels.hg38.NCBI_GRCh38.vcf.gz"
GATK="$PROJECT/containers/gatk_4.6.2.0.sif"

mkdir -p "$PROJECT/bam/recalibrated"

# Check essential inputs before starting
for f in "$REF" "$REF.fai" "$DBSNP" "$MILLS" \
         "$DBSNP.tbi" "$MILLS.tbi" "$GATK"; do
    test -s "$f" || { echo "Missing or empty: $f"; exit 1; }
done

for SAMPLE in PROBAND MOTHER FATHER; do

    INPUT="$PROJECT/bam/marked/${SAMPLE}.markdup.bam"
    TABLE="$PROJECT/bam/recalibrated/${SAMPLE}.recal.table"
    OUTPUT="$PROJECT/bam/recalibrated/${SAMPLE}.recal.bam"

    echo "========== Processing $SAMPLE =========="

    # Step 1: Calculate recalibration statistics
    apptainer exec --bind "$PROJECT:$PROJECT" "$GATK" gatk \
      --java-options "-Xmx16g" BaseRecalibrator \
      -R "$REF" \
      -I "$INPUT" \
      --known-sites "$DBSNP" \
      --known-sites "$MILLS" \
      -O "$TABLE"

    # Step 2: Apply recalibration to BAM
    apptainer exec --bind "$PROJECT:$PROJECT" "$GATK" gatk \
      --java-options "-Xmx16g" ApplyBQSR \
      -R "$REF" \
      -I "$INPUT" \
      --bqsr-recal-file "$TABLE" \
      -O "$OUTPUT" \
      --create-output-bam-index true

    echo "Completed: $SAMPLE"

done

echo "ALL THREE SAMPLES COMPLETED BQSR"
