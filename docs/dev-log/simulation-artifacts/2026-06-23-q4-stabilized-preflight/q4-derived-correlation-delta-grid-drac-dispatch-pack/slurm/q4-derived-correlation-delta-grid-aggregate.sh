#!/usr/bin/env bash
# DRY-RUN TEMPLATE: run only after the DRAC array and totoro shard finish successfully.
# For SLURM, submit manually with a dependency such as:
# sbatch --dependency=afterok:<array_job_id> q4-derived-correlation-delta-grid-aggregate.sh
set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$PWD}"
ARTIFACT_DIR="${REPO_ROOT}/docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight"
AGGREGATE="${ARTIFACT_DIR}/aggregate-calibrated-grid-delta-shards.R"
SHARD_ROOT="${ARTIFACT_DIR}/q4-derived-correlation-delta-grid-drac-shards"

Rscript --vanilla "${AGGREGATE}" \
  --shard-root="${SHARD_ROOT}" \
  --n-shards=9 \
  --expected-cells=1000 \
  --expected-target-rows=6000 \
  --aggregate-label=drac_hybrid_full_calibrated_grid \
  --compute-rate-mcse=true
