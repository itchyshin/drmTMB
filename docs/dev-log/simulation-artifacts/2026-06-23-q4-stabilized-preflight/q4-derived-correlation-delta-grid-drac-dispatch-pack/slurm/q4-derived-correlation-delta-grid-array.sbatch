#!/usr/bin/env bash
# DRY-RUN TEMPLATE: submit only after a DRAC account/cluster is selected.
#SBATCH --job-name=drmtmb-q4-delta
#SBATCH --array=1-8
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=06:00:00
#SBATCH --account=def-pi-placeholder
#SBATCH --output=logs/%x-%A-%a.out
#SBATCH --error=logs/%x-%A-%a.err

set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
bash "${SCRIPT_DIR}/q4-derived-correlation-delta-grid-array-worker.sh"
