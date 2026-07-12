# After Task: Arc 2a — a `mu` random intercept for every family

## Goal

Give the five families that previously rejected all random effects — `binomial`,
`cumulative_logit`, `skew_normal`, `tweedie`, `zero_one_beta` — an accepted,
evidence-backed ordinary `mu` random intercept `(1 | group)`, so drmTMB can
honestly claim "at least a random intercept on the mean, everywhere." Executed as
the ultra-plan `docs/dev-log/2026-07-12-arc2a-random-intercept-all-families-ultra-plan.md`.

## Implemented

Per family: the bar term is now extracted and validated by a family-specific
intercept-only validator (`validate_<family>_mu_random_terms`), the spec threads
`re_mu <- build_random_mu_structure(...)` into `random`, `random_scale`, the
start builder, the `map`, and `random_names`, and the family's TMB branch gained
the standard accumulation block
`eta_mu(i) += mu_re_value(i,j) * exp(log_sd_mu)(term) * u_mu(idx)` plus the
`dnorm(u_mu, 0, 1)` penalty (copied from the working Gamma/gaussian branches).
`binomial` and `zero_one_beta`/`cumulative_logit` additionally needed
`extract_random_mu_terms` inserted (they rejected the bar syntactically).

Four hidden family-gates also had to be extended for the extractors and
diagnostics to work: `make_tmb_data` (three per-family blocks hardcoded
`n_mu_re_terms = 0L` + dummy mu-RE arrays — the actual root cause of the initial
NaN objective), the `check_drm` replication/design whitelist, the
`split_tmb_random_effects` (BLUP) whitelist, and the `split_tmb_sdpars` whitelist.

## Mathematical Contract

For a group-level intercept `u_g ~ N(0, sigma_u^2)` entered on the mean-scale
linear predictor `eta_i = x_i' beta + u_{g(i)}` (identity for skew_normal/ordinal
latent, log for tweedie, logit for binomial/zero_one_beta), fitted by maximum
likelihood with the random effect integrated out by the Laplace approximation.
`cumulative_logit` carries no fixed intercept (the ordered cutpoints are the
intercepts), so the zero-mean random intercept is identified without aliasing.

## Files Changed

- `R/drmTMB.R` — five builders, five validators, five start/map helpers, three
  `make_tmb_data` blocks, two extractor whitelists.
- `R/check.R` — replication/design family whitelist.
- `src/drmTMB.cpp` — mu-RE accumulation block in the five family branches
  (model_type 13/15/16/17/18).
- `tests/testthat/test-arc2a-mu-random-intercept.R` (new, four sentinels) +
  the tweedie sentinel in `test-tweedie-location-scale.R`; five stale
  rejection tests updated.
- `NEWS.md`, `docs/design/03-likelihoods.md`, `docs/design/04-random-effects.md`.
- Capability ledger: `cells.tsv` (mc-0059/0225/0463/0538/0567 → implemented /
  verified / point_fit_recovery), `evidence.tsv`, `transitions.tsv`, the
  regenerated surface, and the generator status-count guard.

## Checks Run

- Per-family DG2 sentinels pass (`devtools::test(filter = "arc2a-mu-random-intercept")`
  and the tweedie file): convergence 0, `pdHess`, SD within 0.30 of truth, BLUP
  vs true-effect correlation 0.84–0.97, `profile_targets()` profile-ready,
  `check_drm()` `mu_random_effect_replication = ok`.
- Ledger: `capability_ledger.py --check` OK; ledger unit tests pass; surface regenerated.
- `rcmdcheck --as-cran`: 0 errors, 0 warnings, 1 note (benign new-submission /
  `0.6.0.9000` dev-version). 11593 tests pass. Three pre-existing missing-response
  "gate" tests that asserted RE rejection were updated: mu-RE + response masking
  is a working combination (verified fits converge with `pdHess`), so they now
  assert acceptance.
- `_pkgdown.yml`: added the five #747/#748 topics (`fitted_distribution`,
  `exceedance`, `centile_chart`, `worm_plot`, `qq_plot`) that failed the pkgdown
  reference-index build on `main`; this rides along to clear that CI red-X.

## Tests Of The Tests

The DG2 sentinel is a genuine known-DGP recovery, not a mock: it simulates a
random intercept with `sd_id`, fits, and asserts the recovered `sdpars$mu[["(1|id)"]]`
is within tolerance AND the fitted BLUPs correlate with the true group effects
(>0.45), so a fit that ignored the RE would fail. The slope-rejection assertion
guards scope. The initial smoke caught that the fit converged from a good start
but the objective was NaN — tracing that to `n_mu_re_terms = 0` in `make_tmb_data`
is what surfaced the hidden per-family arrays.

## Consistency Audit

The mu-RE machinery is genuinely shared (builder, `map`, extractors), but it had
FOUR family-gated surfaces that a naive builder+C++ edit would miss. All five
families now appear in each gate consistently. `sigma`/shape/inflation-dpar REs,
random slopes, labelled covariance blocks, and (ordinal) phylo+RE combination
remain rejected and are covered by retained rejection tests.

## GitHub Issue Maintenance

No issue opened for this slice; the parent Arc 2a scope is tracked in the
candidate-arcs plan. A tracking issue should be opened if Arc 2b (slopes) /
Arc 2c (sigma-RE) proceed.

## What Did Not Go Smoothly

Three of five families diverged on the first compile with a NaN objective from a
good start. The cause was not the builder or C++ edits but `make_tmb_data`
hardcoding `n_mu_re_terms = 0L` per family — so `u_mu` was declared random but
unused, making the Laplace marginalization degenerate. Two more whitelists
(`check_drm`, BLUP split) then had to be extended for the diagnostics.

## Team Learning

"The machinery is shared" is only partly true in this codebase: `make_tmb_data`,
`check_drm`, and the parameter-split extractors each carry a per-family allow-list.
Adding a capability to a family means auditing every allow-list, not just the
builder and the likelihood branch. The NaN-from-a-good-start signature reliably
points at a declared-but-unused random parameter (a data/parameter mismatch).

## Known Limitations

ML-Laplace only. With few or small clusters the RE standard deviation can be
biased low (documented in NEWS); AGHQ (the non-Gaussian remedy) and REML remain
planned. Evidence tier is `point_fit_recovery` (DG2) — no multi-seed coverage
study yet (DG3 deferred, pairs with Arc 1/REML).

## Next Actions

1. Confirm `rcmdcheck --as-cran` clean; commit the slice.
2. Optional DG3 multi-seed recovery campaign on Totoro (deferred).
3. Arc 2b (one random slope per family) and Arc 2c (`sigma`-side RE) next.
