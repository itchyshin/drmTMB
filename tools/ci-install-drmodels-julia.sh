#!/usr/bin/env bash
# Instantiate DRModels.jl for repository CI (Julia bridge coverage lane).
# Requires julia-actions/setup-julia to have run and DRModels.jl checked out at
# DRMODELS_JL_PATH (or the first argument).
set -euo pipefail

drmodels=${1:-${DRMODELS_JL_PATH:-}}
if [[ -z $drmodels ]]; then
  echo "usage: $0 <path-to-DRModels.jl-checkout>" >&2
  echo "or set DRMODELS_JL_PATH" >&2
  exit 2
fi

if [[ ! -f $drmodels/Project.toml ]]; then
  echo "DRModels.jl checkout missing Project.toml: $drmodels" >&2
  exit 1
fi

julia --startup-file=no --project="$drmodels" -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

echo "drmodels_jl_path=$(cd "$drmodels" && pwd)"
