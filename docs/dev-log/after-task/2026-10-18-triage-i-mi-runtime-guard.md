# After Task: #1513 runtime guard drmTMB_mi_quadrature_inaccurate

Reader: Shinichi, checking the post-fit `mi()` quadrature warning on draft
PR #1513.

## Goal

Warn after a TMB fit when the estimated Beta / zero-one-Beta prior mean
sits near 0 or 1, or when a Gamma `mi()` CV is at least 3. Keep the
frozen 15-node Beta rule and the two labelled skips. Do not edit
`src/`. Do not add a check before the Julia branch. Push the existing
draft only.

## Implemented

`drm_warn_mi_quadrature_inaccurate()` in `R/mi-weights.R` walks every
enabled `mi()` term (`missing_predictor` and `missing_predictor2`).
`drm_fit_spec()` calls it after the fitted `fn`/`gr` probe, at
`R/drmTMB.R:727`, on `obj$env$parList()`. The class is
`drmTMB_mi_quadrature_inaccurate`. Julia still returns from
`drmTMB_julia_bridge()` before `drm_fit_spec()`, and the joint adapter
already refuses Beta/Gamma `mi()`.

The Beta / zero-one-Beta cut is a missing-row prior mean at or inside
`0.10` of 0 or 1. That is the measured 15-node leftover:
`|logLik - log integrate()|` is `4.65e-3` at `mu = 0.10`, `sigma = 1`
and `4.81e-3` at `mu = 0.02`, `sigma = 1`. Mid-range `mu = 0.50`,
`sigma = 0.5` stays near `2.6e-5`. A pinched `mu = 0.10`, `sigma = 0.2`
case is also inside `2.6e-5`, so a mu-only threshold is conservative
there. Gamma fires at fitted CV `>= 3`.

A live two-`mi()` fit is still Gaussian+Gaussian only. The second-slot
test therefore uses a live two-Gaussian `drmTMB()` object, relabels the
second term as Gamma at CV 3.5, and checks that the helper warns on
slot 2 while slot 1 stays healthy. Live single-term Beta (`mu ~ 0.04`)
and Gamma (CV 3) fits warn through `drmTMB()`. A healthy Gamma CV 0.10
fit does not.

## Mathematical Contract

Beta missing-row mean `m_i = logit^{-1}(W_i hat{alpha})`, clamped by
`drm_beta_missing_predictor_inverse_link()`. Warn if any missing row
has `m_i <= 0.10` or `m_i >= 0.90`. Gamma CV is `exp(log_sigma_mi)`.
Warn if `CV >= 3`. The 15-node Gauss-Legendre rule and the 51-node
log-`x` Gamma rule are unchanged.

## Files Changed

- `R/mi-weights.R`: helper, thresholds, both-slot loop.
- `R/drmTMB.R`: one call after the fitted probe.
- `tests/testthat/test-mi-quadrature-1476-1477.R`: second-slot helper,
  live two-`mi()`, live Beta, live Gamma, healthy Gamma.
- `inst/extdata/env-skip-census.tsv`: cran-lane 5→9.
- `NEWS.md`, `docs/design/03-likelihoods.md`,
  `docs/dev-log/known-limitations.md`, check-log.
- C17 receipt
  `docs/dev-log/implementation-recovery/2026-10-18-mi-quadrature-1513-guard-c17c2-c14-final-source-compatibility`.

## Checks Run

Focused (R 4.3.3, TMB 1.9.25, `NOT_CRAN=true`):
`test-mi-quadrature-1476-1477.R` 0 fail / 175 pass / 2 labelled skips
(Beta `mu = 0.02` and Gamma CV `>= 3`); `test-env-skip-census.R` 0 fail
/ 5 pass.

C17 `--label mi-quadrature-1513-guard --tolerance 1e-10`: `|change|
0.000e+00` on mc-0568 / 0569 / 0576.
`--check-c14-receipt-equivalence` OK.

Full `testthat::test_dir()`: the Summary reporter prints only the first
10 failures, all this VM's missing Suggests (`ape`, `emmeans`,
`mvtnorm`), the same class as Engine A's FAIL 67. In that run
`test-mi-quadrature-1476-1477.R` is 175 pass / 2 labelled skips / 0
fail. Touched mi() files had 0 fail. CI is the green bar.

## Tests Of The Tests

The second-slot helper fails if only `missing_predictor` is read (a
healthy Gaussian first term plus Gamma CV 3.5 second used to be
silent). The live two-Gaussian fit fails the mutation check if
`log_sigma_mi2` is ignored. The healthy Gamma CV 0.10 fit fails if the
warning fires on every `mi()` model.

## Consistency Audit

```
rg "drm_warn_mi_quadrature_inaccurate" R tests
rg ":1434|:1475|:4678" R/mi-weights.R NEWS.md
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" R NEWS.md docs/design/03-likelihoods.md
```

Unweighted prior cites stay `:1434`, `:1475`, `:4678`. `src/` is
untouched. The warning is only wired in `drm_fit_spec()`, not before
`engine = "julia"`. No `Fixes` lines.

## GitHub Issue Maintenance

No issue filed. U-shaped Beta stays refs #1476 / #1531. Gamma CV
`>= 3` leftover stays
`docs/dev-log/2026-10-12-gamma-mi-cv-gt1-pole-follow-up-issue.md`
(refs #1477). The new warning reports those leftovers; it does not
close them.

## What Did Not Go Smoothly

A first live Gamma DGP with intercept-only `x ~ 1` and CV 3.5 exploded
to CV 430 and later aborted as non-finite. The shipped live test uses
`x ~ z`, CV 3, and a moderate response slope, which converges at
fitted CV 3.26.

## Team Learning

Two live `mi()` terms cannot mix families. A second-slot Beta/Gamma
warning has to be a helper on a live two-Gaussian object, plus live
single-term `drmTMB()` fits for the families that actually fire.

## Known Limitations

The 15-node Beta rule at `mu = 0.02` / `0.10`, `sigma = 1` remains
inaccurate; the guard now warns when the fitted missing-row mean sits
in that region. Gamma CV `>= 3` remains the follow-up draft; the guard
now warns at fitted CV `>= 3`. The mu-only Beta cut is conservative
for a pinched `mu = 0.10`, `sigma = 0.2` prior.

## Next Actions

Push `cursor/triage-i-mi` (no force). Keep the PR draft. Confirm CI on
the new head. Do not merge.
