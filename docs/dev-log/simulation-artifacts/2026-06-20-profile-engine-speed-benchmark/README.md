# Profile-engine speed benchmark: endpoint solver vs tmbprofile — diagnostic

**Date:** 2026-06-20 · **Author:** Ada (autonomous) · **Outcome:** speed diagnostic (no cell change)

drmTMB's `confint(method = "profile")` exposes `profile_engine = c("auto",
"endpoint", "tmbprofile")`. The **endpoint** engine root-finds directly for the two
CI endpoints of DIRECT scale/SD/correlation targets; **tmbprofile** evaluates a full
profile grid. This benchmarks per-call wall-clock time (block-timed over 10 calls to
beat clock resolution) and confirms the two engines agree on the endpoints.

## Result (`tables/profile-engine-benchmark.csv`)

| target | endpoint | tmbprofile | speedup | max endpoint diff |
| --- | --- | --- | --- | --- |
| gaussian sigma (scale), n=2000 | 44 ms | 137 ms | **3.1x** | 2.9e-6 |
| relmat SD, n_id=80 | 1152 ms | 5001 ms | **4.3x** | 1.4e-5 |
| phylo SD, 120 species | 377 ms | 1848 ms | **4.9x** | 1.1e-5 |

(machine-specific timings; the ratio is the portable quantity.)

## Findings

- **The endpoint engine is ~3-5x faster than tmbprofile** on endpoint-eligible
  (direct scale/SD/correlation) targets, and the gain GROWS with model cost: the
  structured GMRF SD targets (relmat, phylo), where each objective evaluation is
  expensive, benefit most. The endpoint solver needs only a handful of constrained
  re-optimizations per side vs the full grid tmbprofile evaluates.
- **The two engines agree** on the CI endpoints to <= 1.4e-5 across all three
  targets, so the speed-up is not a precision trade-off.
- **`auto` already uses endpoint** for these direct scale/SD/correlation targets, so
  users get the fast path by default there.

## Speed-up opportunities (for the owner's "manage + speed up profile" steer)

1. **Extend the endpoint solver to fixed-effect coefficients.** Today coefficients
   (e.g. `rho12 ~ x` betas, `mu` betas) fall back to tmbprofile even under `auto`
   (the endpoint engine covers only direct scale/SD/correlation targets). The rho12
   profile calibration (`2026-06-20-rho12-profile-calibration/`) therefore ran on
   the slow path. A coefficient endpoint solver would bring the same ~3-5x to
   coefficient profiles -- the single highest-value R-side profile speed-up.
2. **Parallelise profiling across targets/replicates** (profile is currently
   per-target sequential; `parallel`/`workers` exist for bootstrap).
3. **"maximized in Julia" = in-process direct DRM.jl.** Profile and bootstrap are
   "re-optimize many times" workloads -- exactly where Julia's compiled objective +
   AD + cheap warm-started re-solves pay off. The callr bridge cannot deliver it
   (each round-trip is ~3 min of startup/compile). The honest home is the "Julia
   speedups" matrix row (experimental/planned): an in-process DRM.jl profile/bootstrap
   loop is the direction. Julia profile is partially wired (`drm_julia_profile_targets`)
   but gated on a stored bridge payload and unvalidated.

## How to reproduce

```sh
cd /Users/z3437171/.codex/worktrees/540b/drmTMB
/usr/local/bin/Rscript --vanilla \
  docs/dev-log/simulation-artifacts/2026-06-20-profile-engine-speed-benchmark/run.R 10
```

## Boundary

Native R/TMB timing diagnostic on one machine; the speedup ratio is the portable
result, not the absolute ms. Endpoint-eligible targets only (scale/SD/correlation).
No matrix/finish cell changed.
