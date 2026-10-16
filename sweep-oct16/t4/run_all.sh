#!/usr/bin/env bash
# sweep-oct16 / t4: full pipeline, run from the drmTMB checkout root.
# Needs: R with drmTMB installed from the pinned commit; Julia with DRModels.jl at the pinned commit.
# DRMODELS: path to the DRModels.jl checkout; JULIA: julia binary.
set -euo pipefail
T=sweep-oct16/t4
DRMODELS=${DRMODELS:-/home/user/DRModels.jl}
JULIA=${JULIA:-julia}
mkdir -p $T/results $T/logs
Rscript $T/t4_gen_data.R $T/data                                   > $T/logs/gen.log 2>&1
Rscript $T/t4_reference.R $T/data $T/results/reference.csv         > $T/logs/reference.log 2>&1
Rscript $T/t4_unbounded_check.R $T/data $T/results/gauss_unbounded.csv > $T/logs/unbounded.log 2>&1
Rscript $T/t4_fit_drmTMB.R $T/data $T/results/fits_drmTMB          > $T/logs/fit_drmTMB.log 2>&1
$JULIA --project=$DRMODELS $T/t4_fit_DRModels.jl $T/data $T/results/fits_DRModels.csv > $T/logs/fit_DRModels.log 2>&1
Rscript $T/t4_analyse.R                                            > $T/logs/analyse.log 2>&1
echo "done"
