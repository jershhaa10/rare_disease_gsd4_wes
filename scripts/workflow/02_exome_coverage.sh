#!/bin/bash
set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
BED="$PROJECT/reference/S07604514_Covered_NCBI_GRCh38_merged.bed"
OUT="$PROJECT/qc/coverage"

mkdir -p "$OUT"

echo -e "Sample\tMean_Depth\tPercent_20x" > "$OUT/exome_coverage.tsv"

for SAMPLE in PROBAND MOTHER FATHER; do

    echo "Processing $SAMPLE..."

    samtools depth -a \
        -b "$BED" \
        "$PROJECT/bam/marked/${SAMPLE}.markdup.bam" |
    awk -v sample="$SAMPLE" '
    {
        sum += $3
        total++
        if ($3 >= 20) covered20++
    }
    END {
        if (total == 0) exit 1
        printf "%s\t%.2f\t%.2f\n",
               sample, sum/total, 100*covered20/total
    }' >> "$OUT/exome_coverage.tsv"

done

echo "Exome coverage analysis complete!"
