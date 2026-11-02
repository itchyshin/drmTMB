# 2026-10-26: Julia probit phylogenetic SD prediction order

The focused `julia-binomial-phylo-sd` test passed 49 expectations, including two
live Julia bridge fits (logit and probit) and their native TMB comparisons. The
probit case checks positive slope recovery within 0.3 of truth and permutes
species rows in `newdata` to check prediction order. A separate run of the
fixed-seed Julia fit estimated the SD slope as 0.326 for a truth of 0.5.
JuliaCall used Julia 1.10.0. The first run could not find Julia because
the login shell omitted Juliaup from `PATH`; the rerun passed with `JULIA_HOME`
and `PATH` set explicitly. These checks cover one synthetic recovery fixture
and output ordering; interval coverage remains uncalibrated. Full output is in
the task transcript; exact command:

```sh
PATH="/Users/z3437171/.juliaup/bin:$PATH" \
JULIA_HOME="/Users/z3437171/.juliaup/bin" \
JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 \
DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" \
Rscript -e 'devtools::test(filter = "julia-binomial-phylo-sd")'
```

Details: `docs/dev-log/after-task/2026-10-26-julia-binomial-phylo-prediction-order.md`.
