This directory contains small helper scripts that are part of the Nextflow
pipeline itself.

- `gencore_multiqc_custom.py`: builds MultiQC custom-content files from GenCore
  JSON reports and links to Nextflow execution reports.

The larger custom analysis scripts are expected to be baked into the pinned
`python_custom` container and are intentionally not tracked in this repository.
