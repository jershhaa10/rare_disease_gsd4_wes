# Containerization

This trio-WES project uses Apptainer containers on a SLURM-managed HPC cluster.

## Verified tools
- GATK 4.6.2.0: gatk_4.6.2.0.sif
- Ensembl VEP 115.2: vep_115.2.sif

Both applications were successfully launched through Apptainer.

## Verification commands
```bash
apptainer exec gatk_4.6.2.0.sif gatk --version
apptainer exec vep_115.2.sif vep --help
```

## Workflow integration
GATK is used for duplicate marking, BQSR, variant calling, joint genotyping, and variant filtering.
VEP is used for offline functional annotation with a GRCh38 cache.
BWA-MEM, samtools, and bcftools use HPC environment modules.

## Reproducibility
The scripts expect container images in $WES_PROJECT_DIR/containers/.
The images, reference files, VEP cache, and sequencing data are not included in this repository.
Compatible images and resources must be supplied before running the workflow.
Container build recipes and immutable image digests have not been documented.
The adapted workflow has not been rerun end to end.
