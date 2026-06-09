# After Task: Julia Bridge Overhead Reduction

## Goal

Reduce avoidable overhead in repeated `drmTMB(..., engine = "julia")`
Gaussian phylogenetic bridge fits, using the 9,993-tip AVONET/Hackett model as
the live target.

## Implemented

The R bridge now trims the data sent through JuliaCall to model variables,
defines the Julia wrapper once during setup, caches same-tree/same-species
phylogenetic payloads, and reuses Newick serialization for repeated fits. The
paired DRM.jl bridge now caches parsed Newick strings as all-node
`AugmentedPhy` objects.

## Mathematical Contract

No likelihood or formula grammar changed. The admitted model remains
`log_mass ~ hand_wing_z + beak_z + phylo(1 | species, tree = tree)`,
`sigma ~ 1`, fitted by DRM.jl's default all-node sparse L-BFGS route for the
Gaussian phylogenetic mean cell.

## Files Changed

- `R/julia-bridge.R`
- `tests/testthat/test-julia-bridge.R`
- `vignettes/julia-engine.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/benchmarks/julia-bridge-overhead-avonet-2026-06-09.csv`
- `docs/dev-log/after-task/2026-06-09-julia-bridge-overhead-reduction.md`
- DRM.jl paired files: `src/bridge.jl`, `test/test_bridge.jl`, and matching
  DRM.jl dev-log notes.

## Checks Run

```sh
air format R/julia-bridge.R tests/testthat/test-julia-bridge.R
Rscript --vanilla -e 'parse("R/julia-bridge.R"); cat("parse ok\n")'
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R")'
/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia --project=. -e 'using Test; include("test/test_bridge.jl")'
Rscript --vanilla -e 'rmarkdown::render("vignettes/julia-engine.Rmd", output_dir = "/tmp/drmtmb-julia-engine-preview", quiet = TRUE)'
rg -n "17\\.222|3\\.5 times|3\\.55|2\\.6.*17\\.2|3\\.784|16\\.15|hundredths" vignettes/julia-engine.Rmd /tmp/drmtmb-julia-engine-preview/julia-engine.html docs/dev-log/check-log.md docs/dev-log/benchmarks/julia-bridge-overhead-avonet-2026-06-09.csv
git diff --check
```

Results: R bridge tests passed with 53 expectations, DRM.jl bridge tests passed
with 32 expectations, the article rendered, and `git diff --check` was clean in
both touched repositories.

## Tests Of The Tests

The R test now proves that unused data columns are dropped, R-side same-tree
payloads are reused, and the restored row order still matches the original
data. The DRM.jl test proves that repeated Newick strings return the cached
parsed tree object.

## Consistency Audit

The Julia-engine article now reports the updated 9,993-tip row:
`61.113 s` native TMB, `3.784 s` Julia bridge, and `2.623 s` direct DRM.jl
kernel. The old `17.222 s` bridge row remains in the check log only as
pre-overhead-pass historical evidence and is marked as superseded.

## GitHub Issue Maintenance

No GitHub issue was opened or updated in this pass. The work is still local and
the repositories already have uncommitted bridge/article changes from the
ongoing Julia-engine slice.

## What Did Not Go Smoothly

The first warm timing split showed that only caching the Newick string was not
enough: repeated R phylogenetic payload construction still cost about `2.227 s`.
Adding same-tree/same-species row-order payload caching reduced that repeated
step to `0.022 s`.

## Team Learning

For profile/bootstrap work, benchmark cold setup and warm repeated refits
separately. The cold 9,993-tip tree serialization still cost about `10.269 s`,
but warm repeated bridge fits now avoid nearly all of that cost.

## Known Limitations

The new timing is a local warm-session smoke, not a release-grade benchmark.
It uses one AVONET/Hackett model, three warm Julia bridge repetitions, BLAS and
OpenMP pinned to one thread, and a single machine. It does not yet measure
threaded profile/bootstrap execution from R.

## Next Actions

Run a profile/bootstrap benchmark that records cold setup, warm bridge refits,
direct Julia kernel time, R object reconstruction, thread count, BLAS/OpenMP
thread settings, and failure counts.
