# Lane B: numeric kernels (beta-binomial large phi, Tweedie power bound, oracle exclusions)

## 1. Goal

Readers: drmTMB maintainers reviewing compiled likelihood changes, and the
next agent touching `src/drm_numeric.h`.

Lane B of the 2026-10-11 bug-fix campaign owned six issues about density
kernels: #1472, #1468, #1467, #1462, #1324 and #710. The goal was to verify
each claim against current `main` (`75845a3d`), fix the live ones with a
regression test that fails before and passes after, and park anything that
needs an owner decision.

## 2. Implemented

**#1467, beta-binomial at large phi.** The kernel was the plain lgamma sum
`lchoose + lgamma(phi) - lgamma(n + phi) + lgamma(y + a) - lgamma(a) + ...`,
whose terms grow like `phi log(phi)`. On `main`, 300 binomial(10, 0.3) rows gave a
compiled objective 2.5 log-units off the binomial limit at `log_sigma = -12`,
57 off at -14, and +5.2e5 at -20 (above the limit, which a beta-binomial
log-likelihood cannot reach). The issue's own pure-R arithmetic understated
it: TMB's compiled `lgamma()` is less accurate than R's at these arguments.
New helpers in `src/drm_numeric.h`:

- `drm_log1p_accurate(x)`: series below 1e-4, the Goldberg correction
  `log(u) x / (u - 1)` above.
- `drm_lgamma_ratio(x, m) = lgamma(x + m) - lgamma(x)`: direct below
  `x = 100`, analytic Stirling difference
  `(x - 1/2) log1p(m/x) + m log(x + m) - m + S(x + m) - S(x)` above.
- `drm_beta_binomial_log_density(y, n, a, b)`: three ratios.

The `model_type == 14` main loop and the `drm_response_log_density()` case 14
leaf now call it. After the fix the same 300 rows match an exact
product-form reference to 1e-8 at every `log_sigma` from -2 to -20 and equal
the binomial limit at -20.

**#1468, Tweedie power boundary.** Confirmed and worse than reported. NaN at
`|eta_nu| >= 37` as stated, but TMB's `tweedie_logW()` caps its series at
`TWEEDIE_NTERM = 20000` terms, so as `p -> 2` the window stops covering the
peak and the log-density falls off a cliff long before: y = 1, mu = 1,
phi = 1 gives -1.0 at `eta_nu = 14`, -33.6 at 20 and +6 at 36 (true limit
-1); y = 10, mu = 7.4, phi = 0.018 already breaks at 11. `eta_nu` now goes
through `drm_softclamp_log_sigma_one(eta_nu, -10, 10, 2)` before `plogis()`:
exact identity on [-10, 10], C1 saturation by +/-12 (the DRModels.jl limit).

**#1324, oracle exclusions.** Carried PR #1439's change (it no longer merges
cleanly): `run_oracle()` defaults to `max_nonfinite = 0L`, the counting
logic is the unit-tested `oracle_kept_nonfinite()`, and six families declare
their observed non-finite counts with a stated mechanism. The second half
of Russell Dinnage's point, that the beta-binomial reference shared the
kernel's cancellation, is fixed too: the reference is now the exact finite
product `sum log(x + k)`, so the `huge_phi` exclusion and its 0.07 sanity
bound are gone and every point is held to 1e-7. On `main` the new oracle
fails on 35 of 175 points, worst 0.066 relative.

## 3a. Decisions and Rejected Alternatives

- Tweedie: a soft clamp, not a hand-written Tweedie series. The cliff comes
  from TMB's term cap and is phi-dependent, so no `eta_nu` bound removes it
  for very small phi. Replacing `dtweedie()` (for example a series window
  centred on `jmax`) is a larger likelihood change and is listed for
  Shinichi's decision.
- Band [-10, 10] + 2 rather than the log-sigma default [-12, 12] + 3: with
  saturation at 15 the y = 1, phi = 1 cell still landed on the cliff edge
  (-1.0069 instead of -1.0).
- The R side still reports `nu = 1 + plogis(eta_nu)` from the raw
  coefficient. It differs from the clamped power by less than 4.5e-5 when a fit
  ends in the margin. A `check_drm()` note for that case belongs in
  `R/check.R` (lane C) and is proposed, not implemented.
- Beta-binomial switch at `x = 100`: Stirling truncation there is below
  6e-18, and the direct branch below it is accurate to about 1e-13.

## 4. Files Touched

- `src/drm_numeric.h`: three new helpers, appended at the end so PR #1504's
  edits to `drm_log1mexp()` / `drm_log1p_nonnegative()` merge cleanly.
- `src/drmTMB.cpp`: `model_type == 14` main loop (outside the `has_mi`
  blocks) and `model_type == 16` power.
- `src/drm_response_kernels.h`: case 14 leaf.
- `tests/testthat/test-beta-binomial-large-phi.R`,
  `tests/testthat/test-tweedie-power-bound.R`: new.
- `tests/testthat/test-numeric-kernel-oracle.R`: #1439 carry plus the new
  beta-binomial reference.
- `docs/design/03-likelihoods.md`: Tweedie and beta-binomial sections.

## 5. Checks Run

Built with `R CMD INSTALL --no-docs` into `/tmp/rlib` (patched) and
`/tmp/rlib_main` (unmodified `75845a3d`), R 4.3.3, TMB 1.9.10.

| test file | main | this branch |
| --- | --- | --- |
| `test-tweedie-power-bound.R` | 49 fail / 39 pass | 0 fail / 88 pass |
| `test-beta-binomial-large-phi.R` | 11 fail / 15 pass | 0 fail / 26 pass |
| `test-numeric-kernel-oracle.R` | not run | 2 fail + 1 error, all `tweedie` package missing here |

Full suite: see the PR comment for the totals of the background
`testthat::test_dir()` run.

## 6. Tests of the Tests

Each new test was run against the unmodified build first (counts above). The
beta-binomial oracle was also run point by point against `main`: 35 grid
points exceed 1e-7.

## 7a. Issue Ledger

- #1467: fixed with tests.
- #1468: NaN and the cliff above `eta_nu = 12` fixed with tests; small-phi
  series cliff (TMB) needs a decision.
- #1324: fixed for `run_oracle()` and the beta-binomial reference (carries #1439, which can be closed as superseded). The first tweedie oracle block now counts its dropped points too, with #1440's measured bound of 86 of 126 (reference-side `tweedie::dtweedie()` underflow), and asserts the kernel finite at every point. I could not re-measure the 86 here because the `tweedie` package is unavailable; CI is the first real check. #1440's `newton_polish = FALSE` workaround is not carried, so #1440 needs a rebase onto this PR or can be closed.
- #1462, #1472: already fixed in open draft PR #1504 (same functions); not
  duplicated here to avoid conflicting hunks.
- #710: findings 1, 3, 4, 5, 6 were already merged (issue comments of
  2026-07-04 and 2026-07-21). Finding 2 (sigma start constant) needs a
  decision. The 2026-10-04 comment about `check_known_v()` is in `R/check.R`
  (lane C).

## 9. What Did Not Go Smoothly

Two open PRs (#1504, #1439) already covered three of the six issues. That
cost a detour before coding.

The Tweedie and beta-binomial
symptoms in the issue bodies were computed in base R, and the compiled
kernels were worse than that arithmetic in both cases. Kernel claims need a
compiled probe (`obj$fn` at fixed parameters) before choosing a fix.

## 10. Known Residuals

- mi() beta-binomial covariate prior (`mi_family == 12`, `src/drmTMB.cpp`
  ~1801 and ~1825) still uses the old lgamma sum, and its `phi` has no clamp.
  These lines are inside the `has_mi` blocks, so they are left for whoever
  lands the mi() work (Cursor #1513); swap in
  `drm_beta_binomial_log_density()` there. The response leaf (case 14) is
  fixed and now tested through an mi() fit.
- TMB `dtweedie()` small-phi cliff (also the pre-existing
  `log_sigma <= -8` oracle finding).
- Gamma and beta use the same `lgamma(shape)` pattern; not changed.

## 11. Team Learning

When a reference formula shares the kernel's algebra, an oracle cannot see the
kernel's cancellation. Prefer exact finite forms (`sum log(x + k)`) for
discrete families.
