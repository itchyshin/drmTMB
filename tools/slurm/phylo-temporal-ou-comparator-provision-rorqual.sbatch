#!/bin/bash
# Extend the sealed G12 Linux R library with an offline glmmTMB closure.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --job-name=drmtmb-phylo-ou-cmp-provision
set -euo pipefail
: "${DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_AUTHORIZED:?Explicit comparator-campaign authorization token is required}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_DEP_ARCHIVE:?Set sealed glmmTMB dependency archive in /scratch}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_SOURCE_ARCHIVE:?Set immutable drmTMB source archive in /scratch}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_STAGE_ROOT:?Set fresh /scratch campaign staging root}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_BASE_RLIB:?Set verified G12 R library path}"
[[ "${SLURM_CLUSTER_NAME:-}" == rorqual && -n "${SLURM_JOB_ID:-}" ]] || { echo 'Refusing execution outside a scheduled Rorqual job.' >&2; exit 2; }
module load StdEnv/2023 r/4.4.0
export R_PROFILE_USER=/dev/null OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1
stage_root="$DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_STAGE_ROOT"
base_rlib="$DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_BASE_RLIB"
dep_archive="$DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_DEP_ARCHIVE"
source_archive="$DRMTMB_PHYLO_TEMPORAL_OU_COMPARATOR_SOURCE_ARCHIVE"
[[ "$stage_root" == /scratch/* && "$base_rlib" == /scratch/* && -f "$dep_archive" && -f "$source_archive" ]] || { echo 'Comparator provisioning inputs must be sealed /scratch paths.' >&2; exit 2; }
[[ -d "$base_rlib/drmTMB" && -d "$base_rlib/TMB" ]] || { echo 'Verified G12 base library is incomplete.' >&2; exit 2; }
campaign_rlib="$stage_root/Rlib"
[[ ! -e "$campaign_rlib" ]] || { echo 'Refusing to overwrite a campaign library.' >&2; exit 2; }
node_root="${SLURM_TMPDIR:-/tmp}/drmtmb-phylo-ou-cmp-provision-${SLURM_JOB_ID}"
cleanup() { rm -rf "$node_root"; }
trap cleanup EXIT
mkdir -p "$node_root/deps" "$node_root/source" "$stage_root/provision"
cp -a "$base_rlib" "$campaign_rlib"
tar -xzf "$source_archive" -C "$node_root/source"
source_dir="$node_root/source"
[[ -f "$source_dir/DESCRIPTION" ]] || source_dir=$(find "$node_root/source" -mindepth 1 -maxdepth 1 -type d | head -1)
[[ -f "$source_dir/DESCRIPTION" ]] || { echo 'Malformed drmTMB source archive.' >&2; exit 2; }
CXXFLAGS='-O0 -g0' MAKEFLAGS=-e R CMD INSTALL --library="$campaign_rlib" "$source_dir"
tar -xzf "$dep_archive" -C "$node_root/deps"
[[ -f "$node_root/deps/dependency-manifest.csv" && -d "$node_root/deps/packages" ]] || { echo 'Malformed dependency archive.' >&2; exit 2; }
sha256sum -c <(awk -F, 'NR > 1 {gsub(/"/, "", $2); gsub(/"/, "", $3); print $3 "  " $2}' "$node_root/deps/dependency-manifest.csv" | sed "s#  #  $node_root/deps/packages/#")
export R_LIBS="$campaign_rlib${R_LIBS:+:$R_LIBS}"
Rscript --vanilla - "$node_root/deps/packages" "$campaign_rlib" <<'RSCRIPT'
args <- commandArgs(trailingOnly = TRUE)
pkg_dir <- args[[1L]]; lib <- args[[2L]]
files <- list.files(pkg_dir, pattern = '\\.tar\\.gz$', full.names = TRUE)
base <- sub('_.*$', '', basename(files))
# Repeatedly install source packages whose hard dependencies are already
# installed.  This keeps the sealed archive offline and detects an incomplete
# dependency closure rather than falling back to a repository.
remaining <- setNames(files, base)
for (round in seq_len(length(remaining) + 1L)) {
  if (!length(remaining)) break
  progressed <- FALSE
  for (pkg in names(remaining)) {
    td <- tempfile('pkg-desc-'); dir.create(td)
    utils::untar(remaining[[pkg]], files = grep('/DESCRIPTION$', utils::untar(remaining[[pkg]], list = TRUE), value = TRUE), exdir = td)
    desc_path <- list.files(td, pattern = 'DESCRIPTION$', recursive = TRUE, full.names = TRUE)[[1L]]
    d <- read.dcf(desc_path)[1L, , drop = FALSE]
    fields <- intersect(c('Depends', 'Imports', 'LinkingTo'), colnames(d))
    dep_text <- paste(d[, fields, drop = TRUE], collapse = ',')
    deps <- trimws(unlist(strsplit(dep_text, ',', fixed = TRUE)))
    deps <- sub('\\s*\\(.*$', '', deps)
    deps <- deps[nzchar(deps) & deps != 'R']
    unlink(td, recursive = TRUE, force = TRUE)
    available <- vapply(deps, requireNamespace, logical(1L), quietly = TRUE)
    if (all(available)) {
      status <- system2(file.path(R.home('bin'), 'R'), c('CMD', 'INSTALL', '--library', lib, remaining[[pkg]]), env = c('CXXFLAGS=-O0', 'MAKEFLAGS=-e'))
      if (!identical(status, 0L)) stop('Installation failed for ', pkg, call. = FALSE)
      remaining[[pkg]] <- NULL
      progressed <- TRUE
    }
  }
  if (!progressed) stop('No installable package remains: ', paste(names(remaining), collapse = ', '), call. = FALSE)
}
if (length(remaining)) stop('Dependency closure was not installed.', call. = FALSE)
if (!requireNamespace('glmmTMB', quietly = TRUE)) stop('glmmTMB is not loadable after provisioning.', call. = FALSE)
cat('glmmTMB_version=', as.character(utils::packageVersion('glmmTMB')), '\n', sep = '')
RSCRIPT
{
  printf 'run_utc=%s\njob_id=%s\nbase_rlib=%s\nbase_rlib_sha256=%s\ndependency_archive_sha256=%s\nsource_archive_sha256=%s\n' "$(date -Iseconds)" "$SLURM_JOB_ID" "$base_rlib" "$(find "$base_rlib" -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}')" "$(sha256sum "$dep_archive" | awk '{print $1}')" "$(sha256sum "$source_archive" | awk '{print $1}')"
  Rscript --vanilla -e 'cat("drmTMB=", as.character(packageVersion("drmTMB")), "\nglmmTMB=", as.character(packageVersion("glmmTMB")), "\n", sep="")'
} > "$stage_root/provision/job-${SLURM_JOB_ID}.provenance"
printf 'PHYLO_TEMPORAL_OU_COMPARATOR_PROVISION_PASS %s\n' "$SLURM_JOB_ID"
