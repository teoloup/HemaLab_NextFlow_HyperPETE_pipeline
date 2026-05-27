# Hematology Nextflow Pipeline

This is the DSL2 Nextflow implementation of the HyperPETE hematology workflow.

## Layout

- `main.nf`: pipeline orchestrator.
- `modules/`: one module per command/tool stage.
- `conf/containers.config`: pinned container images.
- `assets/`: example parameter files.
- `bin/gencore_multiqc_custom.py`: small helper used to add GenCore and pipeline links to MultiQC.
- `multiqc_config.yaml`: MultiQC configuration.

## Run Example

```bash
nextflow run main.nf \
  -profile docker \
  -params-file assets/params.hpc.example.yml \
  --fastq_dir /path/to/fastqs \
  --outdir /path/to/results \
  --cleanup_work false \
  --bed_file /path/to/panel.bed
```

Switch runtime with `-profile singularity` or `-profile apptainer`.

## Output Model

Each sample publishes into:

```text
results/
  SAMPLE/
    stout_sterr/
    stats/
    cnvkit/
    ...
```

By default, task execution happens under:

```text
<outdir>/work/
```

Keep `cleanup_work: false` while testing so failed/intermediate task directories remain inspectable and `-resume` can work. After validating the pipeline, use `--cleanup_work true` to remove successful work directories automatically at the end of a successful run.

Global artifact-marking outputs are published under:

```text
results/
  cohort/
    stout_sterr/
    marked_artifacts/
```

Every process writes explicit `.out` and `.err` logs into `stout_sterr`, in addition to Nextflow's native `.command.*` files in `work/`.

The pipeline uses `errorStrategy = 'terminate'`, so a failed sample stops the workflow before cohort artifact marking. `MAKE_VCF_LIST` also checks that final merged VCFs exist and fails with a clear error if none are available.

## Important Output Cleanup

Use `--keep-important true` to prune each sample directory after a successful run. The cleanup keeps the final annotated CSV, final merged VCF, normalized caller VCFs and indexes, RG BAMs and indexes, Mutect bamouts, `stats/`, `cnvkit/`, and `stout_sterr/`.

## Containers

Container images are pinned in `conf/containers.config`. Custom images are expected to be pulled from Docker Hub by digest; Docker build contexts and original tool sources are intentionally not included in this repository.
