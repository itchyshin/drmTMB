# After Task: Arc 6 direct lognormal `rho12` interval mechanism

## 1. Goal

Make constant residual association in the exact direct `biv_lognormal()` model
callable through guarded Wald, likelihood-profile, and full joint
parametric-bootstrap intervals, without claiming coverage calibration or
extending uncertainty to staged `associate_pairs()` estimands.

## 2. Implemented

- Allowed the existing profile and confidence-interval machinery to target
  direct lognormal `rho12`; exact bivariate Student-t remains explicitly
  excluded.
- Registered the direct lognormal residual-correlation boundary diagnostic.
- Made the bootstrap simulator replace both response columns from one jointly
  simulated lognormal draw and refit the entire direct model.
- Added a focused API regression test and a reproducible non-empty smoke.
- Documented the estimand, guarded transform, and pre-coverage boundary in the
  direct lognormal contract and bivariate tutorial.

## 3a. Decisions and Rejected Alternatives

The direct exact-likelihood route is the only interval target admitted here.
Wald is retained as a fast link-scale comparator, profile as the intended
likelihood-based route to calibrate, and a whole-model parametric bootstrap as
a robustness and failure diagnostic. Conditional staged-eta Hessian or profile
intervals were rejected because they would omit fitted-margin uncertainty.
Student-t and prediction-interval extensions were rejected as separate
estimands or computational routes requiring their own validation.

## 3b. Mathematical Contract

The target is the constant log-residual correlation `rho12` in the exact joint
lognormal likelihood, not a raw-scale Pearson correlation and not the frozen-
margin copula association `eta`. Wald intervals use the existing guarded
`atanh(rho12)` link and refuse boundary or non-positive-definite-Hessian cases.
Profile endpoints are obtained on the direct joint likelihood and transformed
back to the correlation scale. The parametric bootstrap jointly simulates both
positive responses and refits every model parameter in each replicate.

The staged `eta` estimator remains beta: its stage-2 curvature conditions on
estimated margins, so this implementation supplies no `vcov()`, Wald, profile,
or confidence interval for it.

## 4. Files Touched

- `R/profile.R`
- `R/check.R`
- `R/methods.R`
- `tests/testthat/test-biv-lognormal.R`
- `inst/sim/run/sim_run_biv_lognormal_rho12_smoke.R`
- `docs/design/233-arc6-3-bivariate-lognormal-contract.md`
- `vignettes/bivariate-nongaussian.Rmd`
- `man/confint.drmTMB.Rd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-24-arc6-direct-lognormal-rho12-interval-mechanism.md`
- `docs/dev-log/simulation-artifacts/2026-07-24-biv-lognormal-rho12-smoke/`

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  'devtools::document(); devtools::load_all(quiet = TRUE); \
   testthat::test_file("tests/testthat/test-biv-lognormal.R", reporter = "summary"); \
   testthat::test_file("tests/testthat/test-profile-targets.R", reporter = "summary")'
R CMD INSTALL -l /private/tmp/drmtmb-arc6-Rlib .
R_LIBS=/private/tmp/drmtmb-arc6-Rlib \
  Rscript --no-init-file inst/sim/run/sim_run_biv_lognormal_rho12_smoke.R
git diff --check
```

Both focused suites passed. The smoke fit converged with `pdHess = TRUE`,
estimated `rho12 = 0.5577501` for truth 0.5, produced Wald and profile
intervals, and retained all 9/9 bootstrap refits. `git diff --check` passed.

## 6. Tests of the Tests

The direct-lognormal test checks the registered `rho12_tanh` target, guarded
near-boundary refusal, callable Wald/profile/bootstrap routes, and the
still-unavailable prediction-interval surface. The existing profile-target
suite exercises the shared target registry across model types. The smoke is an
independent whole-object check: it simulates, fits, calls all three methods,
and writes diagnostics and interval objects.

## 7a. Issue Ledger

No issue status changed. `gh issue list --state open --limit 100 --search
"biv_lognormal rho12 in:title,body"` returned no overlapping open issue. The
only live evidence record is the branch-local M1 mechanism and smoke artifact;
M2 requires a fresh retained-all-attempts campaign manifest before an issue,
capability, or public reporting status can be updated.

## 8. Consistency Audit

`rho12` is consistently described as direct log-residual association. The
contract and tutorial distinguish it from raw-scale correlation and from staged
`eta`. No formula grammar, likelihood parameterization, response family, or
staged-association inference surface changed. A scan of README, ROADMAP, NEWS,
known limitations, formula grammar, and pkgdown configuration found no claim
that needs widening for this pre-coverage mechanism slice.

## 9. What Did Not Go Smoothly

The first real smoke exposed a bootstrap refit defect: the generic refit call
passed implicit weights to a direct bivariate lognormal model, which correctly
rejects weights. The refit helper now omits weights for exact bivariate
lognormal and Student-t models. The repaired smoke retained all nine refits.

## 10. Known Residuals

This is not coverage evidence, a calibrated reporting recommendation, a
real-data tutorial, a rendered-site verification, a full package check, or a
comparison against an independent numerical likelihood oracle. It does not
cover `biv_student()`, varying `rho12`, random effects, missingness, raw-scale
association, staged `eta` intervals, generic cross-family pairs, or staged
Bernoulli x NB2 inference.

## 11. Team Learning

An endpoint API test cannot prove a bootstrap route is scientifically or
mechanically valid. The one-cell smoke was needed to expose the generic-refit
assumption and should remain the required gate before any replicated campaign.

## 12. Cross-Product Coverage

This mechanism covers only fixed-effect, complete-pair, constant-`rho12`, exact
`biv_lognormal()` models with the existing three direct uncertainty entry
points. It does NOT cover `biv_student()`, response-predictor variation in
`rho12`, random effects, REML, missing responses, prediction intervals,
raw-scale correlation, staged `eta`, or any other direct or cross-family pair.
It also does NOT cover calibration: the n-ladder, failures, and interval
coverage must be established separately on Totoro.

## Next Actions

**LANE RECEIPT: START A FRESH TASK.** Preserve this branch and start the
predeclared direct-lognormal coverage lane from its commit. First read this
report, `docs/design/233-arc6-3-bivariate-lognormal-contract.md`, and the
smoke artifact README. Build a retained-all-attempts manifest for the
`n = 100, 300, 1000` by `rho12 = 0, 0.5, 0.85` ladder, inspect one approved
smoke result, then use Totoro for the replicated campaign. Do not redo the
direct likelihood or interval mechanism, and do not start staged-eta
uncertainty or the real-data tutorial before the direct coverage verdict.
