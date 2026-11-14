#!/bin/bash
# usage: bash mkenv.sh <variant>   -- copies the scale_ext jenv and re-points DRModels at src_<variant>
V=$1; W=$HOME/drm_weak_20261108
export JULIA_DEPOT_PATH=$HOME/drm_ext_20261108/depot PATH=$HOME/.juliaup/bin:$PATH JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
rm -rf $W/jenv_$V; cp -r $HOME/drm_ext_20261108/jenv $W/jenv_$V
cd $W
julia +1.10.12 --project=jenv_$V -e 'using Pkg; Pkg.develop(path=joinpath(ENV["HOME"], "drm_weak_20261108", "src_'$V'")); Pkg.precompile(); println("ok ", VERSION)' 2>&1 | tail -3
