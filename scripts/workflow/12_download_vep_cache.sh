#!/bin/bash
#SBATCH --job-name=vep_cache
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=12:00:00
#SBATCH --output=vep_cache_%j.log

set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"
CACHE="$PROJECT/annotation/vep_cache"
FILE="$CACHE/homo_sapiens_vep_115_GRCh38.tar.gz"
URL="https://ftp.ensembl.org/pub/release-115/variation/indexed_vep_cache/homo_sapiens_vep_115_GRCh38.tar.gz"

mkdir -p "$CACHE"

curl -fL --retry 5 --retry-delay 30 -C - \
  -o "$FILE" "$URL"

echo "Download completed."
ls -lh "$FILE"
