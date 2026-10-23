# N5b local pre-run receipt -- P2 inference-parity, run on the Mac (Totoro's
# Julia embedding is blocked, see leaf-n5's receipt)

estimate_minutes: 10
drmtmb_ref: a1a63613b41deb4308e2be1d011fe39415bdbe51
drmjl_ref: 77513aa0663209b96e53a649d232558515f687fa
tmb_converged: TRUE
julia_converged: TRUE
wall_seconds: 62

D-139 estimate, stated before running: one row (`plain_binomial_nonphylo`,
DRM.jl fixture `test/parity/fixtures/binomial-trials`, n = 180, same
committed data draw used on the Totoro attempt -- no reseed), `method =
"profile"` on both coefficients (`mu:(Intercept)`, `mu:x`), both engines,
single R process, `OPENBLAS_NUM_THREADS=1`. Bootstrap is skipped for this row
because `bootstrap_response_data()` cannot reconstruct a two-column
`cbind(successes, failures)` response (drmTMB#1123, filed from leaf-n5's
finding) -- `wald` and `profile` are unaffected. Expected < 10 minutes.

Command:

```sh
DRM_JL_PATH=/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/7db7461b-e1ee-4ad0-a526-010c1c2e26a6/scratchpad/drmjl-objat \
DRMTMB_P2_OUT=<tsv path> \
DRMTMB_WORKTREE=/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/7db7461b-e1ee-4ad0-a526-010c1c2e26a6/scratchpad/wt-n5 \
JULIA_HOME=$(dirname $(readlink -f ~/.juliaup/bin/julia)) \
OPENBLAS_NUM_THREADS=1 \
Rscript tools/parity-p2-pilot.R --local-prerun
```

Ran in **62 seconds**, well inside the 10-minute estimate. Both engines
converged (TMB `is_converged() = TRUE`; Julia `is_converged() = TRUE`).
`JuliaCall::julia_setup()` worked cleanly on this Mac (confirming the
Totoro blocker is host-specific, not a drmTMB/DRM.jl code defect) -- the
Julia "warm-up" fit took 24.48s (first-call JIT/precompile cost, including a
one-time `LogExpFunctionsInverseFunctionsExt` extension precompile that
printed a scary-looking but harmless stacktrace to stderr and did not affect
the fit), and the timed Julia fit that followed took 0.251s.

## Table

| coefficient | ci_lower_tmb | ci_upper_tmb | ci_lower_julia | ci_upper_julia | endpoint_abs_delta |
|---|---|---|---|---|---|
| mu:(Intercept) [profile] | -0.2997883823 | -0.1077829373 | -0.2997906318 | -0.1077818345 | 2.249e-06 |
| mu:x [profile] | 0.3488908676 | 0.5490818066 | 0.3488907740 | 0.5490841101 | 2.303e-06 |

Max `endpoint_abs_delta` across both coefficients: **2.303e-06**. Both
intervals are finite and in the expected range around the fixture's own
`expected.toml` coefficients (`mu_(Intercept) = -0.2035`, `mu_x = 0.4480`).

This is a PIPELINE proof only: it fits both engines and calls `confint()` on
both for the same draw; it makes no interval-property claim of either
engine's confidence intervals, and touches no capability-ledger row or
dashboard TSV.

## Full pilot estimate

Two additional real timing probes (not part of the required pre-run row, but
needed to extrapolate honestly rather than guess) were taken on the local
Mac, `OPENBLAS_NUM_THREADS=1`, single R process each:

- `biv_gaussian_residual` fixture (`gaussian-bivariate-rho12`, the costliest
  of the four rows: 4 dpars, its own optimizer): TMB fit 0.223s, Julia fit
  28.10s (a **second** first-call JIT tax -- each fresh `Rscript` process
  pays this once; a single long-lived pilot process pays it once total, and
  a parallel pilot pays it once per forked worker), TMB profile (one
  coefficient) 0.503s, TMB bootstrap `R=20` (one coefficient) 2.318s. Julia
  **profile and bootstrap are not available** for this row's fixed-effect
  targets on the Julia engine (`drm_julia_validate_inference_targets()`
  aborts: `"fixef:mu1:x" is not ready for profile or bootstrap intervals`,
  because `drm_julia_wald_targets()` sets `fixef_profile_ready <- !is_biv &&
  ...` and this is a bivariate model) -- only `wald` works cross-engine for
  this row; the abort is a pre-flight R-side check, not a Julia round-trip,
  so it is near-instant, not an added cost.
- `base_gaussian_location_scale` fixture (`gaussian-locscale`): TMB
  bootstrap `R=20` (one coefficient) 1.019s.

Grid (per the re-scope): 4 partial rows x {wald, profile} x 2 engines x 5
seeds, plus bootstrap for the 3 rows whose response is a single stored
column (`base_gaussian_location_scale`, `biv_gaussian_residual`,
`gaussian_response_mask`; `plain_binomial_nonphylo` excluded, #1123) = 20
row x seed cells, each needing one TMB refit + one Julia refit (attempted)
per seed, then per-coefficient CI calls.

Per-(row, seed) cell, steady state (post-JIT), summed over both coefficients
of that row: `plain_binomial_nonphylo` (fit + profile x2, no bootstrap) ~
0.06 + 0.8 = 0.9s TMB-side, ~0.4s Julia-side; `base_gaussian_location_scale`
and `gaussian_response_mask` (fit + profile x2 + bootstrap x2, both
similar-sized univariate models) ~ 2.9s TMB-side, ~1.0s Julia-side each;
`biv_gaussian_residual` (fit + profile x2 + bootstrap x2 on TMB only, Julia
does only `wald` + two near-instant profile/bootstrap aborts) ~ 5.8s
TMB-side, ~0.35s Julia-side. Summed across the 4 rows: ~12.5s TMB-side +
~2.75s Julia-side per seed (steady state) x 5 seeds ~ 76s of total
single-threaded compute, plus one base-model refit per cell (~1-5s summed,
needed to `simulate()` each seed's response) plus R/data-loading overhead.

The dominant, genuinely uncertain cost is the one-time Julia JIT/precompile
tax (24-28s), paid once per forked worker (`parallel::mclapply()`, seeds
split across `DRMTMB_P2_CORES` workers, capped at 6). With 4 workers this
tax runs in parallel (~30s wall, not 4x30s), and the ~76s of steady-state
compute divides roughly across the 4 workers (~20s wall). Total:

full_pilot_estimate_minutes: 5
decision: RUN

5 minutes (rounded up generously from an ~50-90s point estimate, to absorb
per-cell R/data-loading overhead and any repeat of the 28s Julia-JIT tax on
more than one worker) is comfortably under the 30-minute / <=6-core bound, so
the full pilot runs next (`DRMTMB_P2_CORES=4`, well inside the 6-core cap).
