# After Task: Julia Confint Bridge Slice

Supersession note: this note records the temporary bootstrap-only slice as it
stood when written. Later on 2026-06-09, the profile guard was removed for the
same Gaussian phylogenetic SD target after endpoint parity was fixed and
verified; see
`docs/dev-log/after-task/2026-06-09-julia-profile-bridge-parity.md`.

## Goal

Implement Track 2 before article polish: make the R-to-Julia bridge call a
real Julia inference primitive for the first supported Gaussian phylogenetic SD
target, then benchmark the public route against native R.

## Implemented

`drmTMB_julia` objects now retain the bridge payload used to call DRM.jl:
formula strings, marshalled data, serialized tree, bridge options, row order,
and structured-SD tree scale. `profile_targets()` now accepts Julia-engine fits
and lists the admitted target as `sd:mu:phylo(1 | species)` with Julia internal
parameter `resd`.

`confint.drmTMB_julia()` now supports `method = "bootstrap"` for that target.
R owns target naming and response-scale reporting; Julia owns the repeated
bootstrap work through
`DRM.drm_bridge_inference()`, which calls `profile_result()` or
`bootstrap_result()` inside one Julia runtime. The returned interval is
converted from DRM.jl's working `resd` scale to drmTMB's response-scale
phylogenetic SD scale using the stored tree scale.

The R bridge now blocks `method = "profile"` for this target. The 1,000-species
public-route benchmark found that the current DRM.jl sparse profile endpoint
did not match the native R endpoint, so the public method fails with a clear
message rather than returning a fast but wrong profile interval.

## Scope Boundary

This is deliberately not broad Julia inference parity. The supported public
route is the Gaussian `phylo(1 | species, tree = tree)` mean cell with
`sigma ~ 1`, and the supported public interval target is its random-effect SD
through bootstrap. Profile intervals, fixed-effect bootstrap intervals,
non-Gaussian families, phylogenetic scale models, multiple structured terms,
and neighbouring syntax still need explicit target maps, scale transforms, and
parity tests.

## Files Changed

- `R/julia-bridge.R`
- `R/profile.R`
- `NAMESPACE`
- `NEWS.md`
- `tests/testthat/test-julia-bridge.R`
- `vignettes/julia-engine.Rmd`
- `docs/dev-log/check-log.md`
- `../DRM.jl/src/DRM.jl`
- `../DRM.jl/src/bridge.jl`
- `../DRM.jl/test/test_bridge.jl`
- `tools/benchmark-r-julia-bootstrap-refits.R`
- `docs/dev-log/benchmarks/r-julia-public-confint-2026-06-09.csv`
- `docs/dev-log/benchmarks/r-julia-public-confint-2026-06-09-metadata.md`

## Checks Run

```sh
air format R/julia-bridge.R R/profile.R tests/testthat/test-julia-bridge.R
Rscript --vanilla -e 'parse("R/julia-bridge.R"); parse("R/profile.R"); parse("tests/testthat/test-julia-bridge.R"); cat("parse ok\n")'
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'
/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia --project=/Users/z3437171/Dropbox/Github\ Local/DRM.jl /Users/z3437171/Dropbox/Github\ Local/DRM.jl/test/test_bridge.jl
JULIA_NUM_THREADS=4 DRMTMB_BOOT_BENCH_SPECIES=1000 DRMTMB_BOOT_BENCH_B=10 DRMTMB_BOOT_BENCH_R_WORKERS=1,4 DRMTMB_BOOT_BENCH_RUN_PROFILE=true DRMTMB_BOOT_BENCH_PROFILE_WORKERS=1,4 DRMTMB_BOOT_BENCH_RUN_JULIA_CONFINT=true DRMTMB_BOOT_BENCH_JULIA_CONFINT_THREADS=false,true DRMTMB_BOOT_BENCH_RUN_JULIA_BRIDGE=false DRMTMB_BOOT_BENCH_RUN_DIRECT_JULIA=false DRMTMB_BOOT_BENCH_OUT=docs/dev-log/benchmarks/r-julia-public-confint-2026-06-09.csv Rscript --vanilla tools/benchmark-r-julia-bootstrap-refits.R
RSTUDIO_PANDOC=/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/aarch64 Rscript --vanilla -e 'rmarkdown::render("vignettes/julia-engine.Rmd", output_dir = "/tmp/drmtmb-julia-engine-preview", quiet = TRUE); cat("render ok\n")'
```

R focused tests passed with 63 expectations. The Julia bridge test passed with
46 expectations.

A live R-through-Julia smoke fit on a 4-species Gaussian phylogenetic model
confirmed the public route:

- `profile_targets(fit)` returned ready target
  `sd:mu:phylo(1 | species)`.
- `confint(..., method = "bootstrap", level = 0.80, R = 3,
  seed = 20260609, threads = FALSE)` returned `0.2651091` to `0.3148081` with
  `3/3` successful Julia refits.
- `confint(..., method = "profile")` is now blocked for this route pending
  sparse-profile parity.

The live smoke did not pin BLAS threads and reported `julia.blas_threads = 16`,
so it is functionality evidence, not a timing benchmark.

The pinned 1,000-species benchmark used `JULIA_NUM_THREADS = 4` and
BLAS/OpenMP-style low-level thread variables set to one. Results:

- R bootstrap serial: `30.392 s`, `9/10` successful refits.
- R bootstrap multicore, four workers: `9.038 s`, `9/10` successful refits.
- Julia public bootstrap, `threads = FALSE`: `4.483 s`, `10/10` successful
  refits.
- Julia public bootstrap, `threads = TRUE`: `1.066 s`, `10/10` successful
  refits.
- R profile serial: `13.906 s`.
- R profile endpoint multicore, requested four workers and used two endpoint
  workers: `7.691 s`.
- Julia public profile rows were recorded as `profile_unavailable`.
- The article preview now includes a dedicated profile endpoint table: R native
  profile returned `1.162` to `1.351`, current public Julia profile is guarded
  as `profile_unavailable`, and the diagnostic pre-guard Julia sparse profile
  rows are labelled as mismatched and blocked rather than admitted results.

Public Julia bootstrap was `6.78x` faster than R serial and `2.02x` faster
than R multicore without Julia worker threads; with four Julia threads it was
`28.51x` faster than R serial and `8.48x` faster than R multicore.

The article preview rendered to
`/tmp/drmtmb-julia-engine-preview/julia-engine.html`.

## Next Actions

The article preview now describes this as bootstrap-implemented for one target
and still narrow. The next profile task is to harden DRM.jl's sparse endpoint
profiler until `sd:mu:phylo(1 | species)` matches native R on the 1,000-species
row, then rerun the public comparison and remove the profile guard only after
that parity check passes.
