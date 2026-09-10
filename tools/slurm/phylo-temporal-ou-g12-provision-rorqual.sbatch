#!/bin/bash
# Build the Linux R library before the G12 one-dataset smoke/array tasks.
# Submit each stage in this order: foundation, eigen, remaining, drmTMB.
# Dependency stages use the fixed G12 1 CPU, 2 GiB, 30 minute envelope. The
# separately authorised drmTMB build may override only its time limit at
# submission. It compiles with a local low-memory C++ profile, recorded in its
# provenance, because the default Rorqual -O2 profile exceeds the 2 GiB cgroup.
# Logs are written under the shared stage root so a scheduler timeout remains
# diagnosable even if node-local scratch is removed.
#SBATCH --account=def-snakagaw_cpu
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --job-name=drmtmb-phylo-ou-g12-provision

set -euo pipefail

: "${DRMTMB_PHYLO_TEMPORAL_OU_G12_AUTHORIZED:?G12 user authorization token is required}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_G12_DEP_ARCHIVE:?Set the sealed offline dependency archive in /scratch}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_G12_SOURCE_ARCHIVE:?Set the immutable source archive in /scratch}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_G12_STAGE_ROOT:?Set the /scratch campaign staging root}"
: "${DRMTMB_PHYLO_TEMPORAL_OU_G12_PROVISION_STAGE:?Set foundation, eigen, remaining, or drmTMB}"

if [[ "${SLURM_CLUSTER_NAME:-}" != "rorqual" || -z "${SLURM_JOB_ID:-}" ]]; then
  echo 'Refusing execution outside a scheduled Rorqual job.' >&2
  exit 2
fi

module load StdEnv/2023 r/4.4.0
export R_PROFILE_USER=/dev/null
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1

stage_root="$DRMTMB_PHYLO_TEMPORAL_OU_G12_STAGE_ROOT"
[[ "$stage_root" == /scratch/* ]] || { echo 'G12 staging must be under /scratch.' >&2; exit 2; }
campaign_rlib="$stage_root/Rlib"
export R_LIBS="$campaign_rlib${R_LIBS:+:$R_LIBS}"
dep_archive="$DRMTMB_PHYLO_TEMPORAL_OU_G12_DEP_ARCHIVE"
source_archive="$DRMTMB_PHYLO_TEMPORAL_OU_G12_SOURCE_ARCHIVE"
[[ -f "$dep_archive" && -f "$source_archive" ]] || { echo 'Provisioning input archive is absent.' >&2; exit 2; }

stage="$DRMTMB_PHYLO_TEMPORAL_OU_G12_PROVISION_STAGE"
case "$stage" in
  foundation) packages=(cli_3.6.6.tar.gz rlang_1.3.0.tar.gz lifecycle_1.0.5.tar.gz lattice_0.23-1.tar.gz Matrix_1.7-6.tar.gz Rcpp_1.1.2.tar.gz) ;;
  eigen) packages=(RcppEigen_0.3.4.0.2.tar.gz) ;;
  remaining) packages=(TMB_1.9.25.tar.gz nlme_3.1-171.tar.gz digest_0.6.39.tar.gz ape_5.8-1.tar.gz numDeriv_2016.8-1.1.tar.gz) ;;
  drmTMB) packages=() ;;
  *) echo 'Provision stage must be foundation, eigen, remaining, or drmTMB.' >&2; exit 2 ;;
esac

node_root="${SLURM_TMPDIR:-/tmp}/drmtmb-phylo-ou-g12-provision-${SLURM_JOB_ID}"
log_dir="$stage_root/provision/$stage"
mkdir -p "$node_root/deps" "$node_root/source" "$campaign_rlib" "$log_dir"
exec > >(tee -a "$log_dir/job-${SLURM_JOB_ID}.log") 2>&1
printf 'run_utc=%s\nstage=%s\njob_id=%s\n' "$(date -Iseconds)" "$stage" "$SLURM_JOB_ID" > "$log_dir/job-${SLURM_JOB_ID}.provenance"
printf 'source_archive_sha256=%s\ndependency_archive_sha256=%s\n' "$(sha256sum "$source_archive" | awk '{print $1}')" "$(sha256sum "$dep_archive" | awk '{print $1}')" >> "$log_dir/job-${SLURM_JOB_ID}.provenance"

if [[ "$stage" == drmTMB ]]; then
  [[ -d "$campaign_rlib/TMB" ]] || { echo 'TMB must be provisioned before drmTMB.' >&2; exit 2; }
  # A scheduler-killed staged install leaves an empty package directory and a
  # 00LOCK-source directory. Preserve either as evidence, but never replace a
  # loadable installation.
  if [[ -d "$campaign_rlib/drmTMB" ]]; then
    if Rscript --vanilla -e "p <- tryCatch(find.package('drmTMB'), error = function(e) ''); if (!identical(normalizePath(p), normalizePath('$campaign_rlib/drmTMB'))) quit(status = 1); loadNamespace('drmTMB')" >/dev/null 2>&1; then
      echo 'Refuse to replace a loadable provisioned drmTMB library.' >&2
      exit 2
    fi
    partial_dir="$log_dir/partial-before-job-${SLURM_JOB_ID}"
    mkdir -p "$partial_dir"
    mv "$campaign_rlib/drmTMB" "$partial_dir/drmTMB"
    [[ -d "$campaign_rlib/00LOCK-source" ]] && mv "$campaign_rlib/00LOCK-source" "$partial_dir/00LOCK-source"
    printf 'Preserved incomplete drmTMB staged install at %s\n' "$partial_dir"
  elif [[ -d "$campaign_rlib/00LOCK-source" ]]; then
    partial_dir="$log_dir/partial-before-job-${SLURM_JOB_ID}"
    mkdir -p "$partial_dir"
    mv "$campaign_rlib/00LOCK-source" "$partial_dir/00LOCK-source"
    printf 'Preserved incomplete drmTMB install lock at %s\n' "$partial_dir"
  fi
  tar --warning=no-unknown-keyword -xzf "$source_archive" -C "$node_root/source"
  source_dir="$node_root/source"
  [[ -f "$source_dir/DESCRIPTION" ]] || source_dir=$(find "$node_root/source" -mindepth 1 -maxdepth 1 -type d | head -1)
  [[ -f "$source_dir/DESCRIPTION" ]] || { echo 'Source archive does not contain drmTMB DESCRIPTION.' >&2; exit 2; }
  cat > "$node_root/Makevars" <<'EOF'
CXX17FLAGS = -O0 -g0 -fpic
EOF
  printf 'build_profile=low-memory-cxx17-o0\n' >> "$log_dir/job-${SLURM_JOB_ID}.provenance"
  R_MAKEVARS_USER="$node_root/Makevars" R CMD INSTALL --library="$campaign_rlib" "$source_dir"
else
  tar --warning=no-unknown-keyword -xzf "$dep_archive" -C "$node_root/deps"
  dep_dir=$(find "$node_root/deps" -mindepth 1 -maxdepth 1 -type d ! -name '._*' | head -1)
  [[ -n "$dep_dir" ]] || { echo 'Dependency archive has no source directory.' >&2; exit 2; }
  for source_pkg in "${packages[@]}"; do
    pkg_name=${source_pkg%%_*}
    if [[ -d "$campaign_rlib/$pkg_name" ]]; then
      Rscript --vanilla -e "loadNamespace('$pkg_name')"
      printf 'Reusing verified provisioned package: %s\n' "$pkg_name"
    else
      R CMD INSTALL --library="$campaign_rlib" "$dep_dir/$source_pkg"
    fi
  done
fi

printf 'PHYLO_TEMPORAL_OU_G12_PROVISION_PASS %s\n' "$stage"
