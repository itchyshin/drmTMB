#!/bin/bash
# Julia environment on Totoro: DRModels (develop, from the git-archived branch tip) + Distributions + DelimitedFiles.
# usage: bash setup_julia.sh <channel> <env dir> <depot dir>     e.g. 1.10 jenv depot ;  1.12 jenv112 depot112
export JULIA_DEPOT_PATH=$HOME/drm_campaign_20261108/$3
export PATH=$HOME/.juliaup/bin:$PATH
cd $HOME/drm_campaign_20261108
julia +$1 --project=$2 -e 'using Pkg; Pkg.develop(path="DRM.jl"); Pkg.add(["Distributions","DelimitedFiles"]); Pkg.precompile(); using DRModels; println("loaded ", VERSION)'
julia +$1 --project=$2 -e 'using Pkg; Pkg.status()'
