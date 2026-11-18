#!/usr/bin/env bash
set -euo pipefail

repo='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression'
candidate='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia'
scratch='/Users/z3437171/Documents/Codex/2026-10-28/drm-bernoulli-q1.59eBZj'
evidence="$repo/docs/dev-log/general-sd-regression/evidence/bernoulli-q1-independent-20261028"
cd "$repo"
cmp "$candidate/Project.toml" "$scratch/pkg/Project.toml"
cmp "$candidate/Manifest.toml" "$scratch/pkg/Manifest.toml"
python3 tools/general-sd-regression/bernoulli-q1-evidence/pin.py | cmp - "$evidence/sources-before.sha256"

export Q1_SCRATCH="$scratch"
export Q1_EVIDENCE="$evidence"
export DRM_JL_PATH="$scratch/pkg"
export DRMODELS_JL_PATH="$scratch/pkg"
export DRM_JL_JULIA_HOME='/Users/z3437171/.julia/juliaup/julia-1.10.12+0.aarch64.apple.darwin14/Julia-1.10.app/Contents/Resources/julia/bin'
export JULIA_HOME="$DRM_JL_JULIA_HOME"
export JULIA_DEPOT_PATH="$scratch/depot-overlay:/Users/z3437171/Documents/Codex/2026-10-28/drm-julia-parity.ryyLiV/depot:/Users/z3437171/.julia"
export JULIA_PKG_OFFLINE=true
export JULIA_PKG_PRECOMPILE_AUTO=0
export JULIA_NUM_PRECOMPILE_TASKS=1
export JULIA_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export DRMTMB_JULIA_TESTS=true
export NOT_CRAN=true
export R_PROFILE_USER=/dev/null

echo "Q1 run start UTC: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "Q1 R source: $repo"
echo "Q1 Julia source: $candidate (via scratch $scratch/pkg/src)"
echo "Q1 Julia depot: $JULIA_DEPOT_PATH"
bash -c 'echo $$ > "$Q1_SCRATCH/live.pid"; exec /Library/Frameworks/R.framework/Resources/bin/Rscript tools/general-sd-regression/bernoulli-q1-evidence/run.R --live'
echo "Q1 run end UTC: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
