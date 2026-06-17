# R, Julia, Threads, and Multicore Comparison

Date: 2026-06-08

This note records the local timing evidence after installing `{JuliaCall}`.
It separates three concepts that are easy to conflate:

- **Julia threaded** means one Julia process with multiple Julia threads. In the
  current DRM.jl benchmarks, independent bootstrap refits or profile endpoints
  are split with Julia threads, with BLAS pinned to one thread.
- **R multicore** means multiple forked R worker processes through
  `parallel::mclapply()`. This is process-level parallelism, not shared-memory
  Julia threading.
- **R bridge** means `drmTMB(..., engine = "julia")` through `{JuliaCall}`. The
  cold first call includes Julia startup and compilation; warm rows are the
  useful per-fit comparison.

The benchmark tables below therefore record the parallel backend, not only a
core count.

| label | meaning | memory/process model | notes |
|---|---|---|---|
| R none | one R process | single main R process | No explicit `mclapply`; still record hidden BLAS/OpenMP threads. |
| R multicore | `parallel::mclapply()` | multiple forked R worker processes | Unix/macOS fork backend; not available as multicore on Windows. |
| R TMB OpenMP | TMB model-level threading | one R process calling threaded C++/OpenMP code | Applies only when the TMB template is written and compiled for OpenMP; `TMB::openmp()` controls DLL-level TMB threads, not BLAS/LAPACK threads. |
| Julia `threads = false` | one Julia process, one Julia thread | one process | Baseline with no explicit Julia parallel backend. |
| Julia `threads = true` | one Julia process, N Julia threads | shared-memory threads in one process | Controlled by `--threads` or `JULIA_NUM_THREADS`. |

For fair runs, also record low-level thread settings. Otherwise it is easy to
accidentally compare R worker processes times BLAS/OpenMP threads against Julia
threads times BLAS threads. The metadata should include `language`,
`backend`, `n_workers_or_threads`, `process_model`, `BLAS_threads`,
`OpenMP_threads`, and platform.

## Environment

- R: 4.5.2
- Julia: 1.10.0
- JuliaCall: 0.17.6
- TMB: 1.9.21
- BLAS threads: pinned to 1 for direct Julia benchmarks; not independently
  varied in the R bridge smoke rows
- OpenMP threads: not explicitly tested in this slice
- drmTMB checkout: dirty local development checkout
- DRM.jl path: `/Users/z3437171/Dropbox/Github Local/DRM.jl`

## R Native Profile

Command:

```sh
Rscript bench/profile-scalar-endpoint.R --rows 10000 --species 1000 \
  --endpoint-workers 2 \
  --output docs/dev-log/benchmarks/profile-scalar-endpoint-2026-06-08-r-compare.csv
```

Model: synthetic Gaussian phylogenetic mean model with 10,000 rows and 1,000
species. Target: `sd:mu:phylo(1 | species)`.

| engine | backend | workers | elapsed_s | speedup_vs_tmbprofile | status |
|---|---|---:|---:|---:|---|
| `tmbprofile` | none | 1 | 22.606 | 1.00 | ok |
| endpoint | none | 1 | 7.958 | 2.84 | ok |
| endpoint | multicore | 2 | 4.830 | 4.68 | ok |

Endpoint intervals matched `tmbprofile` closely:

- lower difference: `-8.37e-07`;
- upper difference: `2.92e-06`.

Reading: R already has a useful native speedup path for one scalar
phylogenetic SD profile: the endpoint engine avoids the full profile curve, and
two forked workers split the lower and upper endpoints.

## R Native Bootstrap

Ad hoc local run on the same 10,000-row / 1,000-species synthetic model, target
`sd:mu:phylo(1 | species)`, with `R = 20` bootstrap refits.

| route | backend | workers | B | elapsed_s | sec_per_refit | successful | failed | speedup_vs_serial |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| R bootstrap serial | none | 1 | 20 | 61.756 | 3.088 | 20 | 0 | 1.00 |
| R bootstrap multicore | multicore | 4 | 20 | 15.787 | 0.789 | 20 | 0 | 3.91 |

Reading: R multicore bootstrap scales nearly as expected on this small B, but
each worker is a separate R process. This is the right R-native comparator for
bootstrap workflows until the Julia bridge exposes matched bootstrap wrappers.

## Julia Direct Bootstrap

Direct DRM.jl run, not through R:

```sh
julia --project=. --threads=4 bench/avonet_phylo_gaussian_algorithms.jl \
  --g-tols=1e-4 --bootstrap-B=1000 --bootstrap-mode=threaded \
  --out=report/avonet-phylo-gaussian-bootstrap-B1000.md
```

Model: real AVONET/Hackett Gaussian phylogenetic mean model with 9,993 tips and
19,985 all-node states.

| route | backend | workers | B | elapsed_s | sec_per_refit | successful | failed |
|---|---|---:|---:|---:|---:|---:|---:|
| DRM.jl direct bootstrap | Julia threads | 4 | 1000 | 442.041 | 0.442 | 1000 | 0 |

This is not byte-identical to the R synthetic benchmark above, so do not turn
`0.442 / 0.789` into a formal R-vs-Julia speedup. It does show that the large
real-tree Julia bootstrap path is operational at B = 1000.

At the observed rate, B = 10,000 would be about 4,420 seconds, or roughly 74
minutes, on this 4-thread local run.

## Julia Bridge Fixed Gaussian

After installing `{JuliaCall}`, the fixed-effect Gaussian bridge now runs.
Warm timing rows below use `drmTMB(..., engine = "tmb")` and
`drmTMB(..., engine = "julia")` on the same R data and formula.

| n | reps | TMB median_s | Julia bridge median_s | speedup | logLik_diff | max_coef_diff |
|---:|---:|---:|---:|---:|---:|---:|
| 100 | 5 | 0.012 | 0.005 | 2.40 | 6.68e-13 | 1.16e-10 |
| 1000 | 5 | 0.026 | 0.005 | 5.20 | 3.57e-11 | 1.48e-10 |
| 10000 | 5 | 0.174 | 0.014 | 12.43 | 3.09e-09 | 2.50e-09 |

Reading: this is the clean first positive bridge result. The fixed Gaussian
bridge is faster in warm conditions and matches TMB closely on likelihood and
coefficients.

## Julia Bridge Phylo Smoke

The same installed bridge was tested on synthetic ultrametric Gaussian
phylogenetic mean models.

| species | reps | TMB median_s | Julia bridge median_s | TMB / Julia | logLik_diff | max_common_coef_diff | TMB convergence | Julia convergence |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 100 | 3 | 0.069 | 0.120 | 0.58 | 0.00185 | 0.00107 | 0 | 1 |
| 1000 | 3 | 0.697 | 1.090 | 0.64 | 0.18812 | 0.01066 | 0 | 1 |

Reading: do not advertise the phylogenetic bridge as faster yet. The bridge is
callable, and it uses the intended Julia route, but under current default
bridge settings it reports non-convergence and does not meet the likelihood
parity standard. The next bridge slice should expose or choose an appropriate
Gaussian phylo solver/tolerance policy, then rerun the 100, 1000, and AVONET
rows.

## Practical Answer

For the current article and planning:

- Use the fixed Gaussian bridge table as the first real `engine = "julia"`
  speed result.
- Use the R native profile/bootstrap rows to explain one-core versus multicore
  behavior in R.
- Use the direct DRM.jl AVONET B = 1000 row as standalone Julia evidence for
  large-tree repeated refits.
- Keep the phylogenetic bridge speed table out of reader-facing claims until
  convergence and parity pass.
