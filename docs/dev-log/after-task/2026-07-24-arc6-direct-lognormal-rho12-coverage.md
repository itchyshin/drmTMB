# After Task: Arc 6 direct lognormal `rho12` coverage evidence

## 1. Goal

Calibrate guarded Wald, direct-likelihood profile, and joint parametric-
bootstrap intervals for the constant direct `biv_lognormal()` residual
correlation over the predeclared n-ladder, while preserving all failed outer
and bootstrap refits and keeping staged `eta` inference fenced.

## 2. Implemented

- Added a tested retained-attempts coverage driver with an immutable
  `n = 100, 300, 1000` by `rho12 = 0, 0.5, 0.85` grid.
- Ran the all-cell local smoke and an independently installed Totoro smoke.
- Ran the full Totoro campaign from commit `1e5bd429`: 2,700 outer fits and
  537,300 bootstrap refits, with outer and bootstrap ledgers retained locally.
- Added a compact tracked result summary, manifest, failure account, an audited
  open-data penguin tutorial, and a separate staged-eta bootstrap design.

## 3a. Decisions and Rejected Alternatives

The profile interval is the candidate primary method because it reoptimizes the
exact direct likelihood; Wald is a link-scale comparator and the bootstrap is
a full joint-resimulation robustness route. The current staged conditional
curvature and conditional profiles were rejected as uncertainty estimators:
they condition on fitted margins and omit two-stage uncertainty. Student-t,
random effects, missingness, and predictor-varying `rho12` remain separate
arcs.

## 3b. Plan Versus Actual

The predeclared nine-cell grid, 300 outer attempts per cell, 199 bootstrap
attempts per fit, seed base, 90-core limit, and all-attempt policy were used
unchanged. The first Totoro smoke exposed an incomplete isolated package
installation that loaded old version 0.1.4; it was retained as an environment
diagnostic, then a fresh isolated library containing the exact branch was
verified before the valid smoke and campaign. No estimator, grid, gate, or
result was changed after observing coverage.

## 4. Files Touched

- `inst/sim/run/sim_run_biv_lognormal_rho12_coverage.R`
- `tests/testthat/test-biv-lognormal-rho12-coverage-driver.R`
- `tests/testthat/test-biv-lognormal-rho12-coverage-docs.R`
- `docs/dev-log/2026-07-24-arc6-direct-lognormal-rho12-coverage-manifest.md`
- `docs/dev-log/simulation-artifacts/2026-07-24-biv-lognormal-rho12-totoro-coverage/`
- `docs/design/233-arc6-3-bivariate-lognormal-contract.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/236-arc6-6-bernoulli-nbinom2-contract.md`
- `docs/design/240-arc6-staged-eta-uncertainty-followup.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/bivariate-nongaussian.Rmd`
- `DESCRIPTION`
- `docs/dev-log/check-log.md`

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  'devtools::load_all(quiet=TRUE); testthat::test_file(
   "tests/testthat/test-biv-lognormal-rho12-coverage-driver.R", reporter="summary")'
SMOKE=true NCORES=1 BOOTSTRAP_R=9 \
  Rscript --no-init-file inst/sim/run/sim_run_biv_lognormal_rho12_coverage.R
R_LIBS=/private/tmp/arc6-Rlib Rscript --no-init-file -e \
  'devtools::load_all(quiet=TRUE); rmarkdown::render(
   "vignettes/bivariate-nongaussian.Rmd", output_dir="/private/tmp/arc6-vignette-render")'
git diff --check
```

The coverage-driver test passed; the local smoke retained 9 outer and 81
bootstrap rows. The rendered tutorial includes the 333-row complete penguin
example and both uncertainty figures. The focused direct-likelihood,
profile-target, driver, and public-claim guard tests passed. `pkgdown::check_pkgdown()`
and `git diff --check` passed before closeout.

## 6. Tests of the Tests

The campaign test sources the executable driver in smoke mode, then verifies
the exact 9 outer / 81 bootstrap / 27 summary-row counts and the all-attempt
coverage fields. The Totoro run independently checks the installed package
path and records source SHA, package version, host, cores, seeds, and elapsed
time. Existing `test-biv-lognormal.R` retains the independent transformed-scale
normal-density oracle, response swap, boundary, and interval API tests.

## 7a. Issue Ledger

No issue status changed. The coverage evidence is branch-local until the final
review and rendered-site checks agree on the narrow tested-domain statement.

## 7b. Independent review

Noether confirmed that the direct likelihood, guarded atanh transform,
simulator, target registry, and retained ledgers describe the same `rho12`
estimand, but initially held the public claim until stale capability surfaces
and artifact provenance were repaired. Rose independently held the same claim
until the checksums, limitations page, and a cross-surface wording guard were
present. Those repairs are included here. Fisher's fresh verdict is GO only for
the predeclared fixed-effect `n = 300, 1000` cells and `rho12 = 0, 0.5, 0.85`;
the exact-binomial-overlap gate is a calibration rung, not universal nominality.
Florence caught an interval-display error during the rendered-vignette audit:
the figure had used interval midpoints as points. It now plots the fitted
`rho12` and labels the retained bootstrap fraction (43/99) as a diagnostic.

## 8. Consistency Audit

All direct evidence refers to log-residual `rho12`, never raw-scale correlation
or staged `eta`. The simulator generates correlated lognormal residuals, and
the fit uses the matching direct formulas. The tutorial labels its raw scatter
as descriptive and prints bootstrap failures rather than presenting a smooth
interval as a universal guarantee. The staged design explicitly refuses an API
until a full-refit bootstrap or validated Godambe estimator exists.

## 9. What Did Not Go Smoothly

The first Totoro smoke loaded an old package because the initial isolated
installation was incomplete. A fresh isolated library fixed that environmental
error. In the valid campaign, one outer fit reported false convergence despite
`pdHess = TRUE`; two high-correlation endpoint profiles failed constrained
re-optimization; and 278 bootstrap refits were non-converged. Every event is
retained and reported rather than filtered away.

## 10. Known Residuals

The campaign does not prove lognormal adequacy for any particular data set,
including penguins. It does not cover `biv_student()`, predictor-varying
`rho12`, random effects, missing responses, weights, offsets, REML, raw-scale
correlation, `association()` eta, generic cross-family pairs, or staged eta
SEs/CIs/profiles. The public package site has not yet been rebuilt from this
branch (the source vignette was rendered and `pkgdown::check_pkgdown()` passed),
and the full 117 MB bootstrap ledger remains local rather than tracked.

## 11. Team Learning

An isolated compute installation must be checked for the exact package export
before interpreting a smoke. More importantly, interval availability and
conditional coverage alone are not enough: conservative all-attempt coverage,
endpoint failures, and bootstrap-refit counts need to appear together in the
reader-facing evidence.

## 12. Cross-Product Coverage

This arc covers only exact direct `biv_lognormal()` with complete positive
pairs, fixed-effect covariate-adjusted locations, intercept-only `sigma1`,
`sigma2`, and `rho12`, ML fitting, and the stated n/rho grid. It does NOT cover
Student-t, other families, raw-scale association, staged eta, association
slopes, random/structured effects, missingness, weights, offsets, REML,
predictor-varying scale/correlation, prediction intervals, or package-wide
non-Gaussian inference.

## Next Actions

Complete fresh Fisher, Noether, and Rose review; run the final focused tests,
pkgdown render/check, and site visual audit; then commit and open a reviewable
PR. The staged-eta full-refit-bootstrap design is a future fresh task, not a
continuation of this direct evidence claim.
