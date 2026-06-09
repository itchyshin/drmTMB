# After-task: R, Julia, threads, and multicore comparison

Date: 2026-06-08

## Summary

Installed `{JuliaCall}` in the active R 4.5 arm64 library and ran the first local
R/J bridge smoke from the dirty local drmTMB checkout to the sibling DRM.jl
checkout. Added benchmark artifacts comparing:

- R native profile: `tmbprofile`, endpoint serial, endpoint multicore;
- R native bootstrap: serial versus multicore;
- warm fixed-effect Gaussian `engine = "tmb"` versus `engine = "julia"`;
- phylogenetic Gaussian bridge smoke.

## Evidence

Files:

- `docs/dev-log/benchmarks/r-julia-threading-comparison-2026-06-08.md`
- `docs/dev-log/benchmarks/profile-scalar-endpoint-2026-06-08-r-compare.csv`
- `docs/dev-log/benchmarks/bootstrap-phylo-2026-06-08-r-compare.csv`
- `docs/dev-log/benchmarks/julia-bridge-fixed-gaussian-2026-06-08.csv`
- `docs/dev-log/benchmarks/julia-bridge-phylo-gaussian-2026-06-08.csv`

Main results:

- Fixed Gaussian bridge is now a positive result: at `n = 10000`, warm native
  TMB median was `0.174s`, warm Julia bridge median was `0.014s`, with
  `logLik` difference `3.09e-09`.
- R native phylogenetic SD profile, 10,000 rows / 1,000 species:
  `tmbprofile = 22.606s`, endpoint serial `7.958s`, endpoint multicore with two
  workers `4.830s`.
- R native bootstrap on the same synthetic phylo model, `B = 20`:
  serial `61.756s`, multicore with four workers `15.787s`, 20/20 successful in
  both.
- Phylogenetic Julia bridge is callable but not ready for a speed claim under
  current defaults: the 100- and 1000-species smoke rows were slower than native
  TMB, returned Julia convergence code `1`, and had non-negligible likelihood
  differences.

## Threading Terminology

Julia `threads = true` is shared-memory threading inside one Julia process.
R `parallel = "multicore"` is Unix forked process parallelism via
`parallel::mclapply()`. Both are parallel execution, but they have different
startup, memory, and package-loading costs.

Follow-up wording now appears in the benchmark note and Julia-engine vignette:
benchmark rows should label the backend (`none`, `multicore`, `OpenMP`,
`JuliaThreads`), process model, worker/thread count, BLAS threads, OpenMP
threads, and platform. This avoids comparing R forked workers times hidden
BLAS/OpenMP threads against Julia threads times hidden BLAS threads.

Second prose pass:

- Added a plain-language definition of BLAS and OpenMP to the Julia-engine
  vignette.
- Added the direct DRM.jl AVONET/Hackett sparse phylo bootstrap thread-scaling
  smoke as a non-bridge result: B = 100 took `178.230s` on one Julia thread and
  `20.291s` on 20 Julia threads, with BLAS/OpenMP pinned to one thread.
- Kept B = 10000 labelled as projected from the B = 100 rate, not as a
  completed benchmark.

## Next

The immediate bridge fix is to expose or choose a better Gaussian phylo
solver/tolerance policy for `engine = "julia"`, then rerun the 100/1000/9993
species parity rows before adding reader-facing phylogenetic speed claims.
