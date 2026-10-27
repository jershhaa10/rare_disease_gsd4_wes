#!/bin/bash
#SBATCH --job-name=gsd4_proband
#SBATCH --partition=short
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=10:00:00
#SBATCH --output=proband_%j.out
#SBATCH --error=proband_%j.err

set -euo pipefail

module load bwa/0.7.18
module load samtools/1.21

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
REF="$PROJECT/reference/GCF_000001405.40_GRCh38.p14_genomic.fna"

R1="$PROJECT/fastq/SRR27997292_1.fastq"
R2="$PROJECT/fastq/SRR27997292_2.fastq"

RG='@RG\tID:SRR27997292\tSM:PROBAND\tPL:DNBSEQ\tLB:PROBAND_LIB1'

mkdir -p "$PROJECT/bam" "$PROJECT/tmp"


bwa mem -t 6 -R "$RG" "$REF" "$R1" "$R2" \
    2> "$PROJECT/bam/PROBAND.bwa.log" \
    | samtools sort -@ 2 -m 2G \
        -T "$PROJECT/tmp/PROBAND_sort" \
        -o "$PROJECT/bam/PROBAND.sorted.bam.tmp" -

mv "$PROJECT/bam/PROBAND.sorted.bam.tmp" \
   "$PROJECT/bam/PROBAND.sorted.bam"

samtools quickcheck -v "$PROJECT/bam/PROBAND.sorted.bam"

samtools index "$PROJECT/bam/PROBAND.sorted.bam"

samtools flagstat -@ 2 "$PROJECT/bam/PROBAND.sorted.bam" \
    > "$PROJECT/bam/PROBAND.flagstat.txt"

echo "PROBAND alignment completed successfully."
