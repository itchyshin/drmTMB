#!/usr/bin/env bash
# DRY-RUN TEMPLATE: run on totoro only after the maintainer connects/authenticates it.
set -euo pipefail

SHARD_INDEX=9
SHARD_TAG=$(printf "shard_%02d" "${SHARD_INDEX}")
REPO_ROOT="${REPO_ROOT:-$PWD}"
ARTIFACT_DIR="${REPO_ROOT}/docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight"
RUNNER="${ARTIFACT_DIR}/run-calibrated-grid-delta-resumable-smoke.R"
SHARD_ROOT="${ARTIFACT_DIR}/q4-derived-correlation-delta-grid-drac-shards/${SHARD_TAG}"
mkdir -p "${SHARD_ROOT}"

Rscript --vanilla "${RUNNER}" \
  --n-rep=500 \
  --seed-start=202607500 \
  --sd-scales=0.35,0.50 \
  --cell-limit=1000 \
  --n-shards=9 \
  --allow-large=true \
  --shard-index="${SHARD_INDEX}" \
  --run-label="r63_totoro_compute_${SHARD_TAG}" \
  --output-root="${SHARD_ROOT}/cells" \
  --manifest-dir="${SHARD_ROOT}" \
  --manifest-file="q4-derived-correlation-delta-grid-${SHARD_TAG}-manifest.tsv" \
  --run-log-dir="${SHARD_ROOT}" \
  --run-log-file="q4-derived-correlation-delta-grid-${SHARD_TAG}-run-log.tsv" \
  --force=true \
  --reset-output=true \
  --reset-log=true

Rscript --vanilla "${RUNNER}" \
  --n-rep=500 \
  --seed-start=202607500 \
  --sd-scales=0.35,0.50 \
  --cell-limit=1000 \
  --n-shards=9 \
  --allow-large=true \
  --shard-index="${SHARD_INDEX}" \
  --run-label="r63_totoro_resume_${SHARD_TAG}" \
  --output-root="${SHARD_ROOT}/cells" \
  --manifest-dir="${SHARD_ROOT}" \
  --manifest-file="q4-derived-correlation-delta-grid-${SHARD_TAG}-manifest.tsv" \
  --run-log-dir="${SHARD_ROOT}" \
  --run-log-file="q4-derived-correlation-delta-grid-${SHARD_TAG}-run-log.tsv" \
  --force=false
