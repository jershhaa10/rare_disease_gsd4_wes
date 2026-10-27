#!/bin/bash
#SBATCH --job-name=GSD4_VEP
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=03:00:00
#SBATCH --output=vep_full_%j.out
#SBATCH --error=vep_full_%j.err

set -euo pipefail

PROJECT="${WES_PROJECT_DIR:-/scratch/$USER/rare_gsd4_wes}"

module load bcftools/1.21

echo "Job started: $(date)"
echo "Node: $(hostname)"

bash "$PROJECT/scripts/13_full_vep.sh"

echo "Job finished: $(date)"
