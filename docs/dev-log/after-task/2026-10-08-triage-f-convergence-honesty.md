# After Task: Triage F convergence honesty

## Goal

An applied user, and the next package contributor, should be able to tell a
usable Wald standard error from a fit that only looks converged. This task
closes three honesty gaps on one draft pull request: exact aliasing in any
distributional design (#1470), a dispersion coefficient sitting on a
simpler-family limit (#1496), and a Hessian condition number that shouted
about covariate units (#1251).

## Implemented

Exact rank deficiency is refused before `MakeADFun()`. `drm_fit_spec()` runs
`drm_abort_rank_deficient_designs()` on every matrix in `spec$X`, and the
Julia bridge runs the same check on the R `model.matrix()` it would have
sent as coefficient labels. The QR tolerance is `1e-10`. The message names
the aliased columns and uses class `drmTMB_rank_deficient_design`. Columns
are not dropped, because the only pre-fit handling the mean design already
had was the REML refusal, which stops rather than rewriting the model.

A dispersion coefficient whose design column is nonzero only on limit rows
keeps its point estimate. `summary()` sets that Wald standard error to `NA`.
Wald `confint()` sets `lower` and `upper` to `NA`, `conf.status` to
`boundary_limit`, and `interval_source` to `not_available`, and warns with
class `drmTMB_dispersion_boundary_warning`. Profile and bootstrap intervals
are not blanked. `print()` states the limit. `check_drm()` adds
`dispersion_boundary` (`warning` when any fitted row is at the limit, `ok`
when the family applies and none is). For NB2 and its variants the limit is
`mu * sigma^2 < 0.001`, the extra variance relative to the Poisson variance,
evaluated at the fitted `mu`. Beta, beta-binomial, and zero-one-beta are
not flagged. `nu > 1000` remains the limit for `student` and `biv_student`
because `nu` is dimensionless. `vcov()` is unchanged. Phase 18 writes
`dispersion_boundary` on each replicate summary and does not muffle the
warning.
`hessian_conditioning` now reports the condition number of the
correlation-scaled fixed-effect covariance when every diagonal entry is
positive. A negative covariance eigenvalue still warns from the raw matrix.
The reported `min_eig=` value is still the raw implied Hessian eigenvalue.

## Mathematical Contract

Location, scale, shape, and coscale are unchanged. For NB2,
`Var(y) = mu + sigma^2 mu^2` and `size = 1/sigma^2`, so
`(Var(y) - mu) / mu = mu * sigma^2`. The Poisson limit is the nested model
`sigma^2 = 0`. The flag treats `mu * sigma^2 < 0.001` as that limit, at the
fitted `mu`. An absolute `sigma^2` cutoff is not used: `mu = 1000` and
`size = 2000` has `sigma^2 = 0.0005` but extra variance `0.5` times the
mean, and that standard error stays. Beta, beta-binomial, and zero-one-beta
have no simpler family at large precision, so they are not flagged.
Student-t `nu = 2 + exp(eta_nu)` above 1000 is the Gaussian limit. Excess
kurtosis is `6 / (nu - 4)`, about 0.006 at `nu = 1000`, and `nu` does not
scale with the response. No likelihood, link, or coefficient value was
rewritten.
`rho12` remains the residual correlation and is not used as a name for these
dispersion limits.

The rank check is a column-pivoted QR. A column is aliased when its residual
falls below `1e-10`. `poly(x, 2) + I(x^2)` is an exact alias because the
orthogonal quadratic already spans `x^2`. A predictor perturbed by noise of
`1e-7` or `1e-9` stays above the tolerance and still fits.

The condition number used for the note is
`cond(D^{-1/2} M D^{-1/2})` with `D = diag(M)` and `M = sdr$cov.fixed`.
That is the condition number of the fixed-effect correlation matrix. It
removes parameter units. The indefinite-Hessian warning still uses the raw
covariance eigenvalue.

## Files Changed

- `R/drmTMB.R`, `R/julia-bridge.R`: pre-fit rank refusal.
- `R/check.R`: dispersion-limit report, correlation-scaled condition number.
- `R/methods.R`, `R/profile.R`, `R/mspl-estimator.R`: blank limit Wald
  standard errors and intervals; `print()` line.
- `inst/sim/R/sim_runner.R`: record `dispersion_boundary` per replicate.
- `R/predict-parameters.R`, `R/plot-parameter-surface.R` consumers: Wald rows that use a blanked coefficient are `boundary_limit` / `not_available`.
- `tests/testthat/test-convergence-honesty-triage-f.R` and updates to
  `test-comparators.R`, `test-gaussian-location-scale.R`,
  `test-phase18-sim-runner.R`.
- `NEWS.md`, `man/check_drm.Rd`, `man/confint.drmTMB.Rd`,
  `docs/dev-log/known-limitations.md`, the C17 receipt under
  `docs/dev-log/implementation-recovery/2026-10-08-triage-f-c17c2-c14-final-source-compatibility/`.

## Checks Run

Review round, local `pkgload::load_all()` on R 4.3.3, 0 failures.
`test-convergence-honesty-triage-f.R` 74 pass. `test-phase18-sim-runner.R`
75 pass. `test-plot-parameter-surface.R` 46 pass. `test-plot-corpairs.R`
48 pass. `test-check-conditioning.R` 31 pass, 2 skip, 1 warn.
`test-check-drm.R` 263 pass, 1 skip, 3 warn. `test-fit-convergence-warning.R`
16 pass. `test-summary.R` 200 pass. `test-summary-derived-rows.R` 10 pass.
`test-nbinom2-location-scale.R` 157 pass.
`test-truncated-nbinom2-location-scale.R` 78 pass, 1 warn.
`test-hurdle-nbinom2.R` 60 pass. `test-zi-nbinom2.R` 59 pass, 2 warn.
`test-gaussian-location-scale.R` 80 pass, 1 skip.
`test-student-location-scale.R` 47 pass. `test-beta-location-scale.R` 85 pass,
2 skip. `test-comparators.R` 32 pass, 17 skip. Total 1361 pass, 23 skip,
7 warn, 0 fail.

C17 recertification used `--label triage-f-review --tolerance 1e-10` after
commit `6f4605b87`. `mean_tau_relative_error` was bit-identical to the
triage-f receipt on all three cells. The model-15 fingerprint is unchanged.

The first round, before this review, was also local `pkgload::load_all()` on
R 4.3.3. No failures in the files below.
Counts are testthat progress glyphs (`.` pass, `S` skip, `W` warning).

| File | Pass | Skip | Warn | Fail |
| --- | ---: | ---: | ---: | ---: |
| `test-convergence-honesty-triage-f.R` | 53 | 0 | 0 | 0 |
| `test-check-conditioning.R` | 31 | 2 | 1 | 0 |
| `test-check-drm.R` | 263 | 1 | 3 | 0 |
| `test-fit-convergence-warning.R` | 16 | 0 | 0 | 0 |
| `test-summary.R` | 200 | 0 | 0 | 0 |
| `test-summary-derived-rows.R` | 10 | 0 | 0 | 0 |
| `test-confint-skew-normal-slant.R` | 5 | 0 | 0 | 0 |
| `test-nbinom2-location-scale.R` | 157 | 0 | 0 | 0 |
| `test-truncated-nbinom2-location-scale.R` | 78 | 0 | 1 | 0 |
| `test-hurdle-nbinom2.R` | 60 | 0 | 0 | 0 |
| `test-zi-nbinom2.R` | 59 | 0 | 2 | 0 |
| `test-gaussian-location-scale.R` | re-run passed | 1 (CRAN) | 0 | 0 |
| `test-student-location-scale.R` | 47 | 0 | 0 | 0 |
| `test-beta-location-scale.R` | 85 | 2 | 0 | 0 |
| `test-gamma-location-scale.R` | 76 | 0 | 0 | 0 |
| `test-lognormal-location-scale.R` | 62 | 0 | 0 | 0 |
| `test-tweedie-location-scale.R` | 82 | 1 | 1 | 0 |
| `test-skew-normal-location-scale.R` | 76 | 0 | 0 | 0 |
| `test-phase18-sim-runner.R` | 73 | 0 | 0 | 0 |
| `test-dinnage-audit-wave4b1.R` | passed | 0 | 1 | 0 |
| `test-comparators.R` | 32 | 17 | 0 | 0 |

The conditioning skips are the platform LAPACK cases already guarded in that
file (non-PD Hessian, no covariance to grade). The comparator skips are
missing `lme4`, `glmmTMB`, and `metafor` on this machine. The new warning in
`test-truncated-nbinom2-location-scale.R` is the dispersion-limit warning on
a scale-extreme fit; the test's assertions still passed. The zi-nbinom2
warnings are the existing log-sigma clamp. The dinnage warning is the
existing Wald variance-component boundary warning.

`python3 tools/recertify-c17.py --label triage-f --tolerance 1e-10` passed.
Against the 2026-09-26 receipt, `mean_tau_relative_error` moved by
`3.030e-12` (mc-0568), `1.322e-11` (mc-0569), and `5.263e-12` (mc-0576).
The model-15 source fingerprint was unchanged
(`5ab7a9640a9356b872086acc15fc431b839e9c2b710d7afe7ff667efb0fad61c`), so this
is rerun float noise of the same order already accepted on main (the
2026-09-26 note recorded `3.119e-12`). `tools/capability_ledger.py --check`
and the C14 receipt-equivalence check inside the recertify script passed.
`R/check.R`, `R/profile.R`, `R/julia-bridge.R`, `R/mspl-estimator.R`, and
`inst/sim/R/sim_runner.R` are not whole-file pins of that receipt. No other
recertify command exists under `tools/`.

Full `devtools::test()`, `devtools::check()`, and `pkgdown::check_pkgdown()`
were not run.

## Tests Of The Tests

The new file failed on the first run because `expect_warning()` returns the
condition. After assigning the summary inside the expectation, InsectSprays
`sigma:sprayE` had estimate `-8.938` and standard error `NA`, and
`confint()` returned `boundary_limit`. The Gaussian location-scale formula
`poly(x, 2) + I(x^2)` then failed the new rank check, which confirmed the
check catches an exact polynomial alias. That test now expects the error and
still fits `I(x^2)` together with interactions on a full-rank formula.

## Consistency Audit

Searches:

```sh
rg "meta_gaussian|tau ~|rho ~" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/design/01-formula-grammar.md vignettes
rg "boundary_limit|correlation-scaled" NEWS.md docs/dev-log/known-limitations.md R/check.R
```

The `tau ~` hits are the existing "do not add this syntax" notes. Formula
grammar and the likelihood design note do not describe rank or conditioning,
and this change does not alter either grammar or the likelihood. `README.md`,
`_pkgdown.yml`, and `docs/dev-log/internal-roadmap.md` did not need a status
change. `NEWS.md` and `docs/dev-log/known-limitations.md` record the
behaviour change and the siblings that remain open.

## GitHub Issue Maintenance

No issue was closed and no issue comment was posted. The draft pull request
uses `Fixes` for #1470, #1496, and #1251 because the reported TMB behaviour
is fixed. Julia `summary()` still prints the raw dispersion Wald standard
error; that sibling is named in the pull request and in the known-limitations
ledger rather than left silent.

## What Did Not Go Smoothly

`graft` is not installed here. The first Gaussian formula test combined
`poly(x, 2)` with `I(x^2)`, which is an exact alias, so the new refusal
broke an existing test until the full-rank part was split from the alias.
`expect_warning()` in testthat 3.3 returns the warning, not the value.
The C17 runner refuses to start while its hardcoded output directory exists;
that tracked directory was moved aside and restored.

## Team Learning

A rank tolerance has to sit below the near-collinear fixtures (`1e-9` and
`1e-7`) or those diagnostics stop being tests and become hard errors. Record
a process note only if the same tolerance collision happens again; it is not
a new standing rule yet.

## Known Limitations

Gaussian, gamma, lognormal, and Tweedie `sigma` are not flagged. The
dispersion flag uses `X %*% beta`, so a random-effect-adjusted `sigma` can
sit on the limit while the fixed coefficient keeps its standard error.
`corpairs()` profile intervals are not masked. Follow-up: Julia `summary()`
and `check_drm.drmTMB_julia` do not blank the dispersion standard error and
do not report `dispersion_boundary` or `hessian_conditioning`. `vcov()` still
returns the raw covariance. An empty-cell interaction still errors and was
not changed.

## Next Actions

This draft must land after PR #1503 (`cursor/triage-d-silent-inputs`, #1452)
and needs a rebase onto that branch. #1503 changes `convergence_status()` to
a scale-free Newton step, `max |sdr$cov.fixed %*% gradient| / SE > 1e-3`,
with the same `0.001` used as an absolute cutoff only when there is no
usable Hessian. This branch does not add a fixed absolute gradient cutoff.
On rebase, keep `drmTMB_gradient_warning` in the Phase 18 ignore list.
`dispersion_boundary` is a summary column, not an ignored warning class.
PR #1501 adds `bootstrap_incomplete` to `interval_status_levels()`; this
branch adds only `boundary_limit`.

An empty-cell interaction such as `y ~ site * trt` still errors as rank
deficient. Whether it should fit like `lm()` with `NA` coefficients is
waiting on Shinichi and was not changed.

Follow-up, not in this draft: Julia `summary()` and `check_drm.drmTMB_julia`
do not blank a Poisson-limit Wald standard error and do not report
`dispersion_boundary` or `hessian_conditioning`.

Watch the draft pull request's CI. Do not merge it and do not close the
issues from this branch.
