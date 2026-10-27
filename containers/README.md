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

## Verified Container Provenance

The Apptainer image metadata identifies these Docker sources:

| Application | Docker source |
|---|---|
| GATK 4.6.2.0 | `broadinstitute/gatk:4.6.2.0` |
| Ensembl VEP 115.2 | `ensemblorg/ensembl-vep:release_115.2` |

Compatible images can be obtained using:

```bash
apptainer pull gatk_4.6.2.0.sif docker://broadinstitute/gatk:4.6.2.0
apptainer pull vep_115.2.sif docker://ensemblorg/ensembl-vep:release_115.2

```

These commands reproduce the container setup from versioned Docker images, but identical binaries are not guaranteed without immutable image digests.

Offline VEP annotation also requires a compatible GRCh38 cache.
