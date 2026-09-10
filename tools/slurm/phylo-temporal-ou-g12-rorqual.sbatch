#!/bin/bash
# G12: one array task = one frozen G11 data set. Submit `--array=1%1` for
# the required smoke, then `--array=1-3500%60` only after its retained receipt.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --job-name=drmtmb-phylo-ou-g12

set -euo pipefail

: "${DRMTMB_PHYLO_TEMPORAL_OU_G12_AUTHORIZED:?G12 user authorization token is required}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_G12_SOURCE_ARCHIVE:?Set the immutable source archive on /project}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_G12_RUN_ROOT:?Set the durable /project campaign root}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_G12_SOURCE_COMMIT:?Set the frozen 40-character source commit}"

if [[ "${SLURM_CLUSTER_NAME:-}" != "rorqual" || -z "${SLURM_JOB_ID:-}" ]]; then
  echo 'Refusing execution outside a scheduled Rorqual job.' >&2
  exit 2
fi
if ! [[ "${SLURM_ARRAY_TASK_ID:-}" =~ ^[0-9]+$ ]] || (( SLURM_ARRAY_TASK_ID < 1 || SLURM_ARRAY_TASK_ID > 3500 )); then
  echo 'Submit an array task ID from 1 through 3500.' >&2
  exit 2
fi
if ! [[ "$DRMTMB_PHYLO_TEMPORAL_OU_G12_SOURCE_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
  echo 'G12 source commit must be a 40-character lowercase SHA.' >&2
  exit 2
fi

module load StdEnv/2023 r/4.4.0
export R_PROFILE_USER=/dev/null
export NOT_CRAN=true
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1
campaign_rlib="$DRMTMB_PHYLO_TEMPORAL_OU_G12_RUN_ROOT/Rlib"
export R_LIBS="$campaign_rlib${R_LIBS:+:$R_LIBS}"

source_archive="$DRMTMB_PHYLO_TEMPORAL_OU_G12_SOURCE_ARCHIVE"
run_root="$DRMTMB_PHYLO_TEMPORAL_OU_G12_RUN_ROOT"
task_id="$SLURM_ARRAY_TASK_ID"
task_label=$(printf 'task-%04d' "$task_id")
archive="$run_root/artifacts/${task_label}.tar.gz"
partial="${archive}.partial-${SLURM_JOB_ID}"
node_root="${SLURM_TMPDIR:-/tmp}/drmtmb-phylo-ou-g12-${SLURM_JOB_ID}-${task_id}"
node_artifact="$node_root/$task_label"
node_source="$node_root/source"

[[ -f "$source_archive" ]] || { echo 'Immutable source archive is absent.' >&2; exit 2; }
[[ ! -e "$archive" && ! -e "$partial" ]] || { echo "Refuse to overwrite retained artifact: $archive" >&2; exit 2; }

cleanup() { rm -rf "$node_root"; }
trap cleanup EXIT
mkdir -p "$node_artifact" "$node_source" "$(dirname "$archive")" "$run_root/metadata"
tar -xzf "$source_archive" -C "$node_source"
source_dir=$(find "$node_source" -mindepth 1 -maxdepth 1 -type d | head -1)
[[ -n "$source_dir" && -f "$source_dir/tools/run-phylo-temporal-ou-g12-task.R" ]] || { echo 'G12 worker is absent from source archive.' >&2; exit 2; }
if [[ "${DRMTMB_PHYLO_TEMPORAL_OU_G12_INITIALIZE_RLIB:-0}" == "1" ]]; then
  [[ ! -d "$campaign_rlib/drmTMB" ]] || { echo 'Refuse to replace an existing frozen G12 R library.' >&2; exit 2; }
  mkdir -p "$campaign_rlib"
  export DRMTMB_PHYLO_TEMPORAL_OU_G12_RLIB_INSTALL="$campaign_rlib"
  Rscript --vanilla -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); install.packages(c("cli", "lifecycle", "TMB", "ape", "numDeriv", "tmbprofile"), lib = Sys.getenv("DRMTMB_PHYLO_TEMPORAL_OU_G12_RLIB_INSTALL"), quiet = TRUE)' \
    > "$node_artifact/dependency-install.log" 2>&1
  R CMD INSTALL --library="$campaign_rlib" "$source_dir" > "$node_artifact/package-install.log" 2>&1
elif [[ ! -d "$campaign_rlib/drmTMB" ]]; then
  echo 'G12 campaign library is missing; only the scheduled smoke may initialise it.' >&2
  exit 2
fi
printf "%s\n" "$DRMTMB_PHYLO_TEMPORAL_OU_G12_SOURCE_COMMIT" > "$source_dir/SOURCE_COMMIT"
{
  echo "run_utc=$(date -Iseconds)"
  echo "job_id=$SLURM_JOB_ID"
  echo "array_task_id=$task_id"
  echo "cluster=$SLURM_CLUSTER_NAME"
  echo "node=${SLURMD_NODENAME:-$(hostname)}"
  echo "source_commit=$DRMTMB_PHYLO_TEMPORAL_OU_G12_SOURCE_COMMIT"
  echo "source_archive=$source_archive"
  echo "source_archive_sha256=$(sha256sum "$source_archive" | awk '{print $1}')"
  echo "campaign_rlib=$campaign_rlib"
} > "$node_artifact/slurm-provenance.txt"
Rscript --version >> "$node_artifact/slurm-provenance.txt" 2>&1
(
  cd "$source_dir"
  DRMTMB_PHYLO_TEMPORAL_OU_G12_SOURCE_COMMIT="$DRMTMB_PHYLO_TEMPORAL_OU_G12_SOURCE_COMMIT" DRMTMB_PHYLO_TEMPORAL_OU_G12_USE_INSTALLED=1 Rscript --vanilla tools/run-phylo-temporal-ou-g12-task.R \
    --task="$task_id" \
    --output-dir="$node_artifact/model-artifact" \
    --source-commit="$DRMTMB_PHYLO_TEMPORAL_OU_G12_SOURCE_COMMIT"
) > "$node_artifact/worker.stdout" 2> "$node_artifact/worker.stderr"
test -f "$node_artifact/model-artifact/TASK_COMPLETE"
tar -C "$node_root" -czf "$partial" "$task_label"
sha256sum "$partial" > "$partial.sha256"
mv "$partial" "$archive"
mv "$partial.sha256" "$archive.sha256"
printf 'PHYLO_TEMPORAL_OU_G12_SLURM_TASK_PASS %s %s\n' "$task_id" "$(awk '{print $1}' "$archive.sha256")"
