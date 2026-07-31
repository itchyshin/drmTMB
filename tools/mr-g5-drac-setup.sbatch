#!/bin/bash
#SBATCH --account=def-snakagaw
#SBATCH --job-name=mr-g5-setup
#SBATCH --time=0-01:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=mr-g5-setup-%j.out

set -euo pipefail
module load StdEnv/2023 r-bundle-bioconductor/3.21
export R_LIBS_USER="$HOME/R/g4g5-lib"
mkdir -p "$R_LIBS_USER"
cd "$HOME/g4g5/drmTMB"
R CMD INSTALL --preclean --library="$R_LIBS_USER" .
Rscript --vanilla -e 'library(drmTMB); cat(as.character(packageVersion("drmTMB")), "\n")'
