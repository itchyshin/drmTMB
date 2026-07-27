#!/bin/bash
# One-time B1 fixture dependency install.  This writes only to the isolated
# B1 library; it is not a drmTMB package or method change.
#SBATCH --job-name=drmTMBB1ape
#SBATCH --account=def-snakagaw_cpu
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=0-00:20:00
#SBATCH --output=logs/%x-%j.out

set -euo pipefail
[[ -n "${SLURM_JOB_ID:-}" ]] || { echo "Refusing login-node execution." >&2; exit 2; }
module load StdEnv/2023 gcc/12.3 r/4.4.0
RLIB="${DRMTMB_B1_RLIB:?isolated B1 R library is required}"
BASE_RLIB="${DRMTMB_BASE_RLIB:?read-only dependency base is required}"
export R_PROFILE_USER=/dev/null R_LIBS="$RLIB:$BASE_RLIB"
Rscript --no-init-file -e 'install.packages("ape", lib = Sys.getenv("DRMTMB_B1_RLIB"), repos = "https://cloud.r-project.org")'
Rscript --no-init-file -e 'library(ape, lib.loc = Sys.getenv("DRMTMB_B1_RLIB")); cat(as.character(packageVersion("ape")), "\\n")'
