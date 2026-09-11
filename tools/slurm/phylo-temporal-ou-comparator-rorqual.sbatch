#!/bin/bash
# Paired comparator: one immutable varying-tree P1--P3 data set per task.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --job-name=drmtmb-phylo-ou-cmp
set -euo pipefail
: "${DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_AUTHORIZED:?Explicit comparator-campaign authorization token is required}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_SOURCE_ARCHIVE:?Set immutable source archive in /scratch}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_DEP_ARCHIVE:?Set offline R dependency archive including glmmTMB}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_STAGE_ROOT:?Set fresh /scratch staging root}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_SOURCE_COMMIT:?Set 40-character source commit}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_WRAPPER_SHA256:?Set wrapper SHA-256}"
[[ "${SLURM_CLUSTER_NAME:-}" == rorqual && -n "${SLURM_JOB_ID:-}" ]] || { echo 'Refusing execution outside a scheduled Rorqual job.' >&2; exit 2; }
[[ "${SLURM_ARRAY_TASK_ID:-}" =~ ^[0-9]+$ && "$SLURM_ARRAY_TASK_ID" -ge 1 && "$SLURM_ARRAY_TASK_ID" -le 3000 ]] || { echo 'Submit task IDs 1 through 3000.' >&2; exit 2; }
[[ "$DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_SOURCE_COMMIT" =~ ^[0-9a-f]{40}$ && "$DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_WRAPPER_SHA256" =~ ^[0-9a-f]{64}$ ]] || { echo 'Malformed campaign fingerprints.' >&2; exit 2; }
module load StdEnv/2023 r/4.4.0
export R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1
stage_root="$DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_STAGE_ROOT"
[[ "$stage_root" == /scratch/* ]] || { echo 'Staging root must be under /scratch.' >&2; exit 2; }
source_archive="$DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_SOURCE_ARCHIVE"
dep_archive="$DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_DEP_ARCHIVE"
[[ -f "$source_archive" && -f "$dep_archive" ]] || { echo 'Source or dependency archive is absent.' >&2; exit 2; }
task="$SLURM_ARRAY_TASK_ID"; label=$(printf 'task-%04d' "$task")
archive="$stage_root/artifacts/$label.tar.gz"; partial="${archive}.partial-${SLURM_JOB_ID}"
[[ ! -e "$archive" && ! -e "$partial" ]] || { echo 'Refusing to overwrite retained artifact.' >&2; exit 2; }
node_root="${SLURM_TMPDIR:-/tmp}/drmtmb-phylo-ou-cmp-${SLURM_JOB_ID}-${task}"; node_source="$node_root/source"; node_artifact="$node_root/$label"
cleanup() { rm -rf "$node_root"; }
on_exit() { code=$?; trap - EXIT; if [[ "$code" -ne 0 && -d "$node_artifact" && ! -e "$archive" ]]; then printf 'exit_code=%s\n' "$code" > "$node_artifact/SLURM_FAILURE.txt"; tar -C "$node_root" -czf "$partial" "$label" 2>/dev/null && mv "$partial" "$archive" || true; fi; cleanup; exit "$code"; }
trap on_exit EXIT
mkdir -p "$node_source" "$node_artifact" "$(dirname "$archive")"
tar -xzf "$source_archive" -C "$node_source"; source_dir="$node_source"
[[ -f "$source_dir/DESCRIPTION" ]] || source_dir=$(find "$node_source" -mindepth 1 -maxdepth 1 -type d | head -1)
[[ -f "$source_dir/tools/run-phylo-temporal-ou-comparator-task.R" ]] || { echo 'Comparator worker absent from source archive.' >&2; exit 2; }
campaign_rlib="$stage_root/Rlib"; export R_LIBS="$campaign_rlib${R_LIBS:+:$R_LIBS}"
[[ -d "$campaign_rlib/drmTMB" && -d "$campaign_rlib/glmmTMB" ]] || { echo 'Provisioned R library lacks drmTMB or glmmTMB.' >&2; exit 2; }
printf '%s\n' "$DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_SOURCE_COMMIT" > "$source_dir/SOURCE_COMMIT"
{
  echo "job_id=$SLURM_JOB_ID"; echo "array_task_id=$task"; echo "cluster=$SLURM_CLUSTER_NAME"; echo "source_commit=$DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_SOURCE_COMMIT"; echo "wrapper_sha256=$DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_WRAPPER_SHA256"; echo "source_archive_sha256=$(sha256sum "$source_archive" | awk '{print $1}')"; echo "dependency_archive_sha256=$(sha256sum "$dep_archive" | awk '{print $1}')";
} > "$node_artifact/slurm-provenance.txt"
(
  cd "$source_dir"
  DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_SOURCE_COMMIT="$DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_SOURCE_COMMIT" DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_USE_INSTALLED=1 Rscript --vanilla tools/run-phylo-temporal-ou-comparator-task.R --task="$task" --output-dir="$node_artifact/model-artifact" --source-commit="$DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_SOURCE_COMMIT"
) > "$node_artifact/worker.stdout" 2> "$node_artifact/worker.stderr"
test -f "$node_artifact/model-artifact/RESULTS.md"
tar -C "$node_root" -czf "$partial" "$label"; checksum=$(sha256sum "$partial" | awk '{print $1}'); mv "$partial" "$archive"; printf '%s  %s\n' "$checksum" "$(basename "$archive")" > "$archive.sha256"
(cd "$(dirname "$archive")" && sha256sum -c "$(basename "$archive").sha256")
printf 'PHYLO_TEMPORAL_OU_COMPARATOR_SLURM_TASK_PASS %s %s\n' "$task" "$checksum"
