#!/bin/bash
set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
BED="$PROJECT/reference/GBE1_CDS_GRCh38.bed"
OUT="$PROJECT/qc/coverage"

mkdir -p "$OUT"

printf "Sample\tMean_Depth\tPercent_20x\tBases_Below_10x\n" \
  > "$OUT/GBE1_coverage.tsv"

for SAMPLE in PROBAND MOTHER FATHER; do

    echo "Processing $SAMPLE..."

    samtools depth -a -b "$BED" \
        "$PROJECT/bam/marked/${SAMPLE}.markdup.bam" |
    awk -v sample="$SAMPLE" '
    {
        sum += $3
        total++
        if ($3 >= 20) covered20++
        if ($3 < 10) low10++
    }
    END {
        if (total == 0) exit 1
        printf "%s\t%.2f\t%.2f\t%d\n",
               sample, sum/total, 100*covered20/total, low10
    }' >> "$OUT/GBE1_coverage.tsv"

done

echo "GBE1 coverage analysis complete!"
