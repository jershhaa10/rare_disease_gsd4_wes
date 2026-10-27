#!/bin/bash
#SBATCH --job-name=gsd4_father
#SBATCH --partition=short
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --time=10:00:00
#SBATCH --output=father_%j.out
#SBATCH --error=father_%j.err

set -euo pipefail

module load bwa/0.7.18
module load samtools/1.21

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
REF="$PROJECT/reference/GCF_000001405.40_GRCh38.p14_genomic.fna"

R1="$PROJECT/fastq/SRR27997290_1.fastq"
R2="$PROJECT/fastq/SRR27997290_2.fastq"

RG='@RG\tID:SRR27997290\tSM:FATHER\tPL:DNBSEQ\tLB:FATHER_LIB1'

mkdir -p "$PROJECT/bam" "$PROJECT/tmp"


bwa mem -t 6 -R "$RG" "$REF" "$R1" "$R2" \
    2> "$PROJECT/bam/FATHER.bwa.log" \
    | samtools sort -@ 2 -m 2G \
        -T "$PROJECT/tmp/FATHER_sort" \
        -o "$PROJECT/bam/FATHER.sorted.bam.tmp" -

mv "$PROJECT/bam/FATHER.sorted.bam.tmp" \
   "$PROJECT/bam/FATHER.sorted.bam"

samtools quickcheck -v "$PROJECT/bam/FATHER.sorted.bam"

samtools index "$PROJECT/bam/FATHER.sorted.bam"

samtools flagstat -@ 2 "$PROJECT/bam/FATHER.sorted.bam" \
    > "$PROJECT/bam/FATHER.flagstat.txt"

echo "FATHER alignment completed successfully."
