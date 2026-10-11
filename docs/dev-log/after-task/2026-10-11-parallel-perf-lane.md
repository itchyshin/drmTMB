# 2026-10-11: parallel and performance lane (#1387, #1247, #1248, #914 and the thread-policy cluster)

Reader: the maintainer deciding which parallel and speed changes to accept,
and the next agent touching `R/profile.R` or the optimizer path.

## What changed

**#1387, profile trace memory.** `drm_profile_trace_object()` wrapped
`obj$fn` and appended `list(par, objective, error)` on every objective
evaluation of `TMB::tmbprofile()`. Its only consumer,
`drm_profile_direct_sd_clamp_trace()`, needed `par` to ask whether any raw
direct-SD log-scale predictor left the clamp band. The trace now keeps one
objective and one error slot per evaluation and reduces the clamp question
on the fly into `clamp = c(active, unavailable)` counts. Models without
direct-SD predictors reduce to the old finiteness check without the
`parList()` reconstruction. The classifier still accepts the old
per-evaluation `evaluations` list, and
`options(drmTMB.profile_trace_par = TRUE)` brings the full trail back.

**#1247, `profile()` parallel.** `profile.drmTMB()` gains
`parallel = c("none", "multicore")` and `workers`. It reuses
`profile_parallel_plan()` and `profile_lapply()`, the same functions
`confint()` already uses. `profile_lapply()` now re-raises the first worker
error (`drm_mclapply_stop_on_error()`), because `mclapply()` otherwise
returns a `try-error` element where the serial path aborts. `simulate()`
stays serial: 200 draws took 0.05 s, so there is nothing to win, and one RNG
stream keeps `set.seed()` behaviour simple.

**Thread policy (#1232, #1237, #1249, #1254, #1236).** New help topic
`?drmTMB-parallel` (`R/parallel-docs.R`), cross-linked from `confint()`,
`profile()` and `drm_control(multi_start)`, and listed in `_pkgdown.yml`.

## Measurements (this container, 4 cores, R 4.3.3, TMB 1.9.10)

| Check | Before | After | Identity |
| --- | --- | --- | --- |
| #1387 trace, 82-par RE fit, 3,020 evals | 6,538.9 KB, 4.70 s | 51.3 KB, 4.03 s | curves and clamp status identical |
| #1387 trace, 83-par direct-SD fit, 3,173 evals | 6,919.6 KB, 5.88 s | 53.7 KB, 6.09 s | curves and clamp status identical |
| #1247 `profile()` 4 targets | 9.51 s serial | 3.97 s multicore(4), 2.40x | `identical()` apart from `elapsed` |
| #1248 4 forked starts (prototype only) | 4.47 s | 1.66 s, 2.70x | per-start objectives bitwise equal in this cell |
| #914 relaxed `inner.control`, Gaussian LS RE | 1.59 s | 1.70 s (0.94x) | estimates bitwise equal |
| #914 relaxed `inner.control`, Poisson RE | 0.17 s | 0.17 s (0.98x) | estimates bitwise equal |
| `TMB::openmp(4)` vs `(1)`, one fit | 3.18 s | 3.02 s (noise) | estimates bitwise equal |

The #1387 times include the clamp check, which moved from after the profile
into the traced objective. Scripts are under the session scratchpad
(`b1387.R`, `b1247.R`, `b1248.R`, `b914.R`, `omp.R`), not in the repository.

## Not implemented, with reasons

**#1248 forked multi_start.** The prototype wins 2.7x, but the serial loop
leaves `obj$env$last.par.best` at the best evaluation across all starts and
warm-starts each start's inner solve from the previous one. Forked workers
cannot update the parent's TMB environment, so an opt-in needs a state
handoff design first. A scoped plan is on the issue.

**#914 `inner.control`.** No speedup and no change in estimates on the two
cells tested; not adopted.

**#1250 OpenMP Makevars and #1254 fit-level threads.** These are API and
build changes needing maintainer sign-off (`SHLIB_OPENMP_CXXFLAGS`, an
`openmp()` wrapper, CRAN portability). Plans are on the issues.

**#1236 PSOCK.** Fitted TMB objects hold external pointers, so a cluster
worker would have to rebuild and refit. Documented in `?drmTMB-parallel`.

**#861 bootstrap shards.** A new result representation and reducer, outside
"small and contained". Plan on the issue.

## Checks

Narrow: `test-arc-d-profile-trace.R` (6 tests), `test-profile-parallel.R`
(3 tests), `test-multi-start.R` (6 tests), all passing. Full-suite shard
results are recorded in the PR body.

## Next

Maintainer sign-off on `profile(parallel=)` (new formals) and on whether the
#1248 state-handoff design is worth building.
