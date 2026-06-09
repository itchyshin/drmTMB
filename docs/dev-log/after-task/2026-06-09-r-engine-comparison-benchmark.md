# After Task: R Engine Comparison Benchmark Harness

## Goal

Make the native `engine = "tmb"` versus experimental `engine = "julia"` speed
comparison rerunnable from R, with enough metadata to separate Julia startup,
bridge overhead, warm repeated fits, convergence, and parity.

## Implemented

Added `tools/benchmark-julia-engines.R`, a deliberate benchmark script for the
supported fixed-effect Gaussian route and the AVONET/Hackett Gaussian
phylogenetic route. The script records first-call timing after clearing the
R-side bridge state, warm repeated-fit timing, likelihood differences,
coefficient/fitted/sigma differences, phylogenetic SD differences, convergence
codes, uncertainty status, and backend metadata. It pins BLAS/OpenMP-style
low-level thread environment variables to one by default so later threaded
profile/bootstrap comparisons have an explicit baseline.

The Julia-engine article now points to the script instead of asking future
readers to reconstruct the timing code from the vignette body.

## Mathematical Contract

No likelihood, formula grammar, or bridge behavior changed. The benchmark uses
the current parity-tested R surface:

- `bf(growth ~ temperature + canopy_open, sigma ~ canopy_open)` for the fixed
  Gaussian row.
- `bf(log_mass ~ hand_wing_z + beak_z + phylo(1 | species, tree = tree),
  sigma ~ 1)` for the AVONET/Hackett phylogenetic row.

The Julia side is still described as DRM.jl's default fitting path from R; the
script does not expose user-selectable Julia algorithms.

## Files Changed

- `tools/benchmark-julia-engines.R`
- `vignettes/julia-engine.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/benchmarks/r-engine-comparison-fixed-smoke-2026-06-09.csv`
- `docs/dev-log/benchmarks/r-engine-comparison-fixed-smoke-2026-06-09-metadata.md`
- `docs/dev-log/benchmarks/r-engine-comparison-2026-06-09.csv`
- `docs/dev-log/benchmarks/r-engine-comparison-2026-06-09-metadata.md`
- `docs/dev-log/after-task/2026-06-09-r-engine-comparison-benchmark.md`

## Checks Run

```sh
air format tools/benchmark-julia-engines.R
Rscript --vanilla -e 'invisible(parse("tools/benchmark-julia-engines.R")); cat("parse ok\n")'
DRMTMB_ENGINE_BENCH_MODE=fixed DRMTMB_ENGINE_BENCH_N=100 DRMTMB_ENGINE_BENCH_REPS=1 DRMTMB_ENGINE_BENCH_OUT=docs/dev-log/benchmarks/r-engine-comparison-fixed-smoke-2026-06-09.csv Rscript --vanilla tools/benchmark-julia-engines.R
DRMTMB_ENGINE_BENCH_MODE=both DRMTMB_ENGINE_BENCH_REPS=3 DRMTMB_ENGINE_BENCH_OUT=docs/dev-log/benchmarks/r-engine-comparison-2026-06-09.csv Rscript --vanilla tools/benchmark-julia-engines.R
Rscript --vanilla -e 'rmarkdown::render("vignettes/julia-engine.Rmd", output_dir = "/tmp/drmtmb-julia-engine-preview", quiet = TRUE)'
git diff --check -- tools/benchmark-julia-engines.R vignettes/julia-engine.Rmd docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-09-r-engine-comparison-benchmark.md docs/dev-log/benchmarks/r-engine-comparison-fixed-smoke-2026-06-09.csv docs/dev-log/benchmarks/r-engine-comparison-fixed-smoke-2026-06-09-metadata.md docs/dev-log/benchmarks/r-engine-comparison-2026-06-09.csv docs/dev-log/benchmarks/r-engine-comparison-2026-06-09-metadata.md
```

The fixed Gaussian smoke completed. For `n = 100`, the first Julia call took
`15.082 s` because it started Julia through JuliaCall, while the warm repeated
Julia-engine fit took `0.053 s` versus `1.002 s` for native TMB in this one
smoke repetition. The engines matched closely:
`logLik_diff = 1.41e-09`, `max_common_coef_diff = 5.65e-06`, both convergence
codes were `0`, and the Julia bridge returned finite `mu` and `sigma`
fixed-effect covariance.

The full R-side comparison completed with three warm repetitions per row.
Fixed Gaussian warm rows were `8.00x`, `12.00x`, and `10.00x` faster through
the Julia engine at `n = 100`, `1000`, and `10000`, with all likelihood
differences below `2e-08`. The AVONET/Hackett phylogenetic warm rows were
`2.58x`, `10.38x`, and `14.52x` faster through the Julia engine at `100`,
`1000`, and `9993` species. The 9,993-species row had native TMB median
`68.405 s`, Julia bridge median `4.710 s`, `logLik_diff = 1.16e-03`, native
TMB convergence code `1`, Julia convergence code `0`, and Julia uncertainty
`partial` for `mu`.

## What Did Not Go Smoothly

The first plain `Rscript` smoke could load `{JuliaCall}` but could not find the
Julia binary on `PATH`. The benchmark script now accepts
`DRMTMB_ENGINE_BENCH_JULIA_BIN` and auto-detects Julia binaries installed under
`~/.julia/juliaup`, recording the selected binary in metadata.

## Known Limitations

The script compares only the currently admitted Gaussian bridge routes. It does
not yet benchmark non-Gaussian families, missing-data routes, weights,
non-default controls, bivariate phylogenetic models, or profile/bootstrap
threading. First-call timing is an in-process benchmark after clearing R-side
bridge state; after the first Julia row it is not a full operating-system cold
start.

## Next Actions

Add a profile/bootstrap benchmark that compares R process-based parallelism
with Julia within-process threading using the same fitted model and thread
metadata.
