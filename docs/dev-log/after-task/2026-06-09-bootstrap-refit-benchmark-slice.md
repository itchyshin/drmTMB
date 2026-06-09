# After Task: Bootstrap and Profile Refit Benchmark Slice

## Goal

Measure the next repeated-refit slice after the single-fit R engine benchmark:
native R/TMB bootstrap and profile refits through public `confint()` versus
benchmark-only Julia-engine and direct DRM.jl repeated inference rows.

## Implemented

Added `tools/benchmark-r-julia-bootstrap-refits.R`. The script builds the real
AVONET/Hackett Gaussian phylogenetic model, fits the native TMB base model,
simulates bootstrap responses through the current `simulate.drmTMB()` contract,
times public native `confint(..., method = "bootstrap")` with serial or
multicore R workers, and optionally times a Julia-engine refit loop over the
same simulated responses.

The script also has an optional direct DRM.jl threaded row, launched from R but
labelled separately, because that path uses DRM.jl's native
`bootstrap_result()` and `profile_result()` rather than the R bridge.

## Contract

No public `confint()` or `drmTMB()` behavior changed. The Julia bridge row is a
benchmark-only loop. It is not a user-facing bootstrap CI implementation and is
not threaded from R yet. A true Julia-threaded R bridge bootstrap should be a
new batch primitive after this benchmark proves the shape.

## Files Changed

- `tools/benchmark-r-julia-bootstrap-refits.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-09-bootstrap-refit-benchmark-slice.md`
- `docs/dev-log/benchmarks/r-julia-bootstrap-refits-2026-06-09.csv`
- `docs/dev-log/benchmarks/r-julia-bootstrap-refits-2026-06-09-metadata.md`
- `docs/dev-log/benchmarks/r-julia-bootstrap-profile-thread-compare-2026-06-09.csv`
- `docs/dev-log/benchmarks/r-julia-bootstrap-profile-thread-compare-2026-06-09-metadata.md`
- `docs/dev-log/benchmarks/direct-drmjl-avonet-bootstrap-n1000-B10-threads-4-2026-06-09.md`
- `vignettes/julia-engine.Rmd`
- `../DRM.jl/bench/avonet_phylo_gaussian_algorithms.jl`

## Checks Run

```sh
air format tools/benchmark-r-julia-bootstrap-refits.R
Rscript --vanilla -e 'invisible(parse("tools/benchmark-r-julia-bootstrap-refits.R")); cat("parse ok\n")'
DRMTMB_BOOT_BENCH_SPECIES=100 DRMTMB_BOOT_BENCH_B=2 DRMTMB_BOOT_BENCH_R_WORKERS=1 DRMTMB_BOOT_BENCH_OUT=/tmp/drmtmb-bootstrap-refit-smoke.csv Rscript --vanilla tools/benchmark-r-julia-bootstrap-refits.R
DRMTMB_BOOT_BENCH_SPECIES=1000 DRMTMB_BOOT_BENCH_B=10 DRMTMB_BOOT_BENCH_R_WORKERS=1,4 DRMTMB_BOOT_BENCH_OUT=docs/dev-log/benchmarks/r-julia-bootstrap-refits-2026-06-09.csv Rscript --vanilla tools/benchmark-r-julia-bootstrap-refits.R
DRMTMB_BOOT_BENCH_SPECIES=1000 DRMTMB_BOOT_BENCH_B=10 DRMTMB_BOOT_BENCH_R_WORKERS=1,4 DRMTMB_BOOT_BENCH_RUN_JULIA_BRIDGE=true DRMTMB_BOOT_BENCH_RUN_PROFILE=true DRMTMB_BOOT_BENCH_PROFILE_WORKERS=1,4 DRMTMB_BOOT_BENCH_RUN_DIRECT_JULIA=true DRMTMB_BOOT_BENCH_DIRECT_JULIA_THREADS=4 DRMTMB_BOOT_BENCH_DIRECT_B=10 DRMTMB_BOOT_BENCH_OUT=docs/dev-log/benchmarks/r-julia-bootstrap-profile-thread-compare-2026-06-09.csv Rscript --vanilla tools/benchmark-r-julia-bootstrap-refits.R
Rscript --vanilla -e 'rmarkdown::render("vignettes/julia-engine.Rmd", output_dir = "/tmp/drmtmb-julia-engine-preview", quiet = TRUE)'
git diff --check -- tools/benchmark-r-julia-bootstrap-refits.R vignettes/julia-engine.Rmd docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-09-bootstrap-refit-benchmark-slice.md docs/dev-log/benchmarks/r-julia-bootstrap-refits-2026-06-09.csv docs/dev-log/benchmarks/r-julia-bootstrap-refits-2026-06-09-metadata.md
Rscript --vanilla -e 'invisible(parse("tools/benchmark-r-julia-bootstrap-refits.R")); cat("R parse ok\n")'
julia --project=../DRM.jl -e 'include(joinpath("..", "DRM.jl", "bench", "avonet_phylo_gaussian_algorithms.jl")); println("Julia include ok")'
git diff --check -- tools/benchmark-r-julia-bootstrap-refits.R vignettes/julia-engine.Rmd docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-09-bootstrap-refit-benchmark-slice.md docs/dev-log/benchmarks/r-julia-bootstrap-profile-thread-compare-2026-06-09.csv docs/dev-log/benchmarks/r-julia-bootstrap-profile-thread-compare-2026-06-09-metadata.md docs/dev-log/benchmarks/direct-drmjl-avonet-bootstrap-n1000-B10-threads-4-2026-06-09.md
(cd ../DRM.jl && git diff --check -- bench/avonet_phylo_gaussian_algorithms.jl)
```

The smoke completed. The 1,000-species AVONET/Hackett benchmark completed and
recorded three rows: R native bootstrap serial `28.999 s` for `B = 10` with
`9/10` successful refits, R native bootstrap multicore with 4 workers `8.018 s`
with `9/10` successful refits, and the benchmark-only Julia bridge loop
`2.458 s` with `10/10` converged refits after a `17.503 s` first Julia call.
The article preview rendered successfully to
`/tmp/drmtmb-julia-engine-preview/julia-engine.html`, and the focused
`git diff --check` passed.
The final R parse check, DRM.jl include check, drmTMB diff check, and sibling
DRM.jl diff check also passed after adding profile and direct-thread rows.

The thread/profile comparison completed on the same 1,000-species fixture.
Bootstrap rows were R serial `30.000 s`, R 4-worker `8.728 s`, warm JuliaCall
bridge loop `2.702 s`, direct DRM.jl serial `2.369 s`, and direct DRM.jl
4-thread `0.872 s`. Profile rows were R serial `14.290 s`, R endpoint
multicore requested 4 but used 2 endpoint workers `8.755 s`, direct DRM.jl
serial `1.815 s`, and direct DRM.jl threaded requested 4 but used 2 endpoint
workers `0.702 s`.

## Interpretation

This is the first R-side repeated-refit bridge timing, but it is still not a
public Julia bootstrap CI implementation. Once JuliaCall is warm, the
benchmark-only loop was about `11.8x` faster than R serial bootstrap and `3.3x`
faster than the 4-worker R multicore row for this local `B = 10` example. From
a fresh R process, Julia setup dominates small jobs; the approximate
cold-start break-even from these slopes is `B = 7` against R serial and
`B = 32` against the 4-worker R row.

The direct DRM.jl primitive is the target design for the next bridge slice:
direct 4-thread bootstrap was about `34.4x` faster than R serial and `10.0x`
faster than R 4-worker bootstrap. Direct threaded profile was about `20.4x`
faster than R serial profile and `12.5x` faster than the R endpoint multicore
row. This profile timing is not interval-scale parity yet: R reports
response-scale `sd:mu:phylo(1 | species)` intervals, while the direct DRM.jl
profile report records the working parameter scale.

## Next Actions

Add a DRM.jl batch bridge primitive so R can ask Julia to run repeated
phylogenetic Gaussian refits inside one Julia process, with Julia threads,
instead of looping from R through JuliaCall one fit at a time. After that
lands, rerun the benchmark at larger `B` values and compare R serial,
R `mclapply()`, the current R-loop bridge, and the new Julia-threaded batch
path.
