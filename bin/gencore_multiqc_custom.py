#!/usr/bin/env python3
import glob
import json
import os
import re


def flatten(value, prefix=""):
    if isinstance(value, dict):
        for key, nested in value.items():
            safe_key = str(key).replace(" ", "_")
            nested_prefix = f"{prefix}.{safe_key}" if prefix else safe_key
            yield from flatten(nested, nested_prefix)
    elif isinstance(value, (int, float, str, bool)) or value is None:
        yield prefix, value


def collect_gencore_rows():
    rows = {}
    metrics = []
    for json_path in sorted(glob.glob("multiqc_inputs/gencore_*/*.json")):
        name = os.path.basename(json_path).replace(".json", "")
        match = re.match(r"(.+)_gencore_(umi2|strict)$", name)
        sample = f"{match.group(1)}_{match.group(2)}" if match else name
        try:
            with open(json_path) as handle:
                data = json.load(handle)
        except Exception:
            continue

        values = {}
        for key, value in flatten(data):
            values[key] = value
            if key not in metrics:
                metrics.append(key)
        rows[sample] = values
    return rows, metrics


def write_gencore_table(rows, metrics):
    if not rows:
        return

    preferred = [
        metric
        for metric in metrics
        if any(
            token in metric.lower()
            for token in [
                "read",
                "umi",
                "dup",
                "dedup",
                "consensus",
                "family",
                "mapped",
                "target",
                "rate",
                "ratio",
                "percent",
            ]
        )
    ]
    selected = (preferred or metrics)[:40]

    os.makedirs("multiqc_inputs/gencore_custom", exist_ok=True)
    with open("multiqc_inputs/gencore_custom/gencore_summary_mqc.tsv", "w") as out:
        out.write('# id: "gencore_summary"\n')
        out.write('# section_name: "GenCore summary"\n')
        out.write(
            '# description: "Summary metrics parsed from GenCore JSON reports. Rows are sample_mode."\n'
        )
        out.write('# plot_type: "table"\n')
        out.write('Sample\t' + '\t'.join(selected) + '\n')
        for sample, values in sorted(rows.items()):
            out.write(
                sample
                + '\t'
                + '\t'.join(str(values.get(metric, "")) for metric in selected)
                + '\n'
            )


def write_pipeline_links():
    os.makedirs("multiqc_inputs/pipeline_custom", exist_ok=True)
    with open("multiqc_inputs/pipeline_custom/pipeline_reports_mqc.html", "w") as out:
        out.write(
            """<!--
id: "pipeline_reports"
section_name: "Pipeline execution reports"
description: "Links to the Nextflow execution reports generated for this run."
-->
<ul>
  <li><a href="../pipeline_info/pipeline_dag.html">Pipeline DAG</a></li>
  <li><a href="../pipeline_info/execution_timeline.html">Execution timeline</a></li>
  <li><a href="../pipeline_info/execution_report.html">Resource report</a></li>
  <li><a href="../pipeline_info/execution_trace.txt">Execution trace table</a></li>
</ul>
"""
        )


if __name__ == "__main__":
    rows, metrics = collect_gencore_rows()
    write_gencore_table(rows, metrics)
    write_pipeline_links()
