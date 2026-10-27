#!/bin/bash
#SBATCH --job-name=gsd4_mother
#SBATCH --partition=short
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --time=10:00:00
#SBATCH --output=mother_%j.out
#SBATCH --error=mother_%j.err

set -euo pipefail

module load bwa/0.7.18
module load samtools/1.21

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
REF="$PROJECT/reference/GCF_000001405.40_GRCh38.p14_genomic.fna"

R1="$PROJECT/fastq/SRR27997291_1.fastq"
R2="$PROJECT/fastq/SRR27997291_2.fastq"

RG='@RG\tID:SRR27997291\tSM:MOTHER\tPL:DNBSEQ\tLB:MOTHER_LIB1'

mkdir -p "$PROJECT/bam" "$PROJECT/tmp"


bwa mem -t 6 -R "$RG" "$REF" "$R1" "$R2" \
    2> "$PROJECT/bam/MOTHER.bwa.log" \
    | samtools sort -@ 2 -m 2G \
        -T "$PROJECT/tmp/MOTHER_sort" \
        -o "$PROJECT/bam/MOTHER.sorted.bam.tmp" -

mv "$PROJECT/bam/MOTHER.sorted.bam.tmp" \
   "$PROJECT/bam/MOTHER.sorted.bam"

samtools quickcheck -v "$PROJECT/bam/MOTHER.sorted.bam"

samtools index "$PROJECT/bam/MOTHER.sorted.bam"

samtools flagstat -@ 2 "$PROJECT/bam/MOTHER.sorted.bam" \
    > "$PROJECT/bam/MOTHER.flagstat.txt"

echo "MOTHER alignment completed successfully."
