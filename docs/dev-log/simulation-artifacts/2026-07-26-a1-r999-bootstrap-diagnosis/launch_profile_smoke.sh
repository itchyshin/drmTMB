#!/usr/bin/env bash
# Run exactly one low-cost profile-versus-bootstrap smoke attempt for each
# pre-registered scalar A1 cell. This is a contract check, not coverage
# evidence. Do not turn this script into the full campaign launcher.

set -euo pipefail
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1

work_dir="$HOME/drm_work"
artifact_dir="$work_dir/a1_profile_smoke_20260726"
script="$work_dir/profile_vs_bootstrap.R"
helper="$work_dir/a1_profile_common.R"

if [[ ! -f "$script" || ! -f "$helper" ]]; then
  printf 'Missing copied smoke sources in %s; copy the two committed scripts first.\n' "$work_dir" >&2
  exit 1
fi

mkdir -p "$artifact_dir"
for cell in 1 2 3; do
  Rscript "$script" "$cell" 1 19 "$artifact_dir" 0 "totoro-smoke"
done

Rscript -e '
  files <- list.files(commandArgs(TRUE)[[1L]], pattern = "\\.csv$", full.names = TRUE)
  x <- do.call(rbind, lapply(files, read.csv, stringsAsFactors = FALSE))
  stopifnot(nrow(x) == 3L,
            all(x$profile_status == "valid"),
            all(x$bootstrap_status == "valid"),
            all(x$wald_status == "valid"))
  print(x[, c("cell_id", "fit_converged", "pdHess", "bootstrap_status",
              "profile_status", "profile_engine", "profile_boundary", "wald_status")])
' "$artifact_dir"
