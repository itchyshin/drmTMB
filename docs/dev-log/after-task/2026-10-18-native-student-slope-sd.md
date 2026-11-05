# After Task: Native Student-t independent-slope SD regression

## 1. Goal

Extend the native Student-t SD-regression route from ordinary location
intercepts to one explicitly selected independent location slope, using only
synthetic data and preserving the existing Student-t likelihood.

## 2. Implemented

The complete-data native Student-t builder now accepts one coefficient-selected
ordinary independent location slope with a fixed-predictor SD formula. The
family adapter continues to refuse correlated blocks and structured effects.
The Student-t response scale `sigma` and degrees-of-freedom parameter `nu`
remain fixed effects in this slice.

## 3a. Decisions and Rejected Alternatives

- Kept the existing formula grammar and activated its coefficient selector for
  this bounded Student-t target.
- Preserved the Student-t likelihood, latent-effect parameterization, and
  existing kernel behavior.
- Treated the recovery fit and interval-route smoke checks as point-recovery and
  workflow evidence, not uncertainty calibration.
- Assumption: the deterministic synthetic case tests the intended slope-loading
  implementation; it does not establish performance across designs or seeds.

## 4. Files Touched

- `R/drmTMB.R`
- `R/random-effect-targets.R`
- `tests/testthat/test-student-sd-regression.R`
- `tests/testthat/test-student-sd-integration.R`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/general-sd-regression/native-family-wave-plan.md`
- `vignettes/location-scale-scale.Rmd`
- `NEWS.md`
- `.unlazy/general-sd-regression/gates/native-student-slope-sd.md`
- `docs/dev-log/check-log.d/2026-10-18-native-student-slope-sd.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-18-native-student-slope-sd.md`

## 5. Checks Run

- Test-first native assembly failed at the expected intercept-only target
  fence. After the change, the same command passed 25 expectations, including
  the correlated-block refusal.
- A fresh package install to
  `/private/tmp/drmtmb-student-slope-library-20261018` succeeded.
- The compiled focused integration suite passed 30 expectations against that
  installation. It includes a synthetic recovery fit, an independent
  slope-loading Laplace oracle, a wrong-group control, constant-SD equivalence,
  prediction, simulation, save/reload, and profile/bootstrap target routing.
- `knitr::knit()` executed every chunk in
  `vignettes/location-scale-scale.Rmd`, including the new Student-t slope
  example. `rmarkdown::render()` was unavailable because `rmarkdown` is not
  installed; Quarto could not identify the sandbox architecture after its
  `sysctl` call was blocked. No HTML artifact or full site was produced.
- `pkgdown::check_pkgdown()` found no problems. Pandoc emitted existing
  `--mathml` deprecation notices.
- `git diff --check` passed before this report correction; it is rerun as part
  of closeout.
- The report structure check initially failed because this note did not use
  the required headings. This corrected version is being checked again before
  closeout.

## 6. Tests of the Tests

The new assembly expectation failed before the adapter change and passed after
it. The compiled integration test compares the fit with a separately coded
groupwise Laplace calculation whose curvature includes the squared slope
loading. Reassigning SD predictors to the wrong groups acts as a negative
control. A separate formula test verifies that correlated intercept-slope
blocks remain refused.

## 7a. Issue Ledger

An open-issue search for “Student random effect SD slope” returned unrelated
skew-normal, simulation-framework, and test-sweep issues. No issue was changed
because none tracks this Student-t SD-regression slice.

## 8. Consistency Audit

The formula selector, group-level SD equation, Student-t location predictor,
family fences, and fitted outputs agree. The family map and location-scale
guide now describe the native Student-t intercept and slope cells separately
from the narrower Julia route. The following status-inventory scans found no
current intercept-only claim requiring an update in the listed neighbouring
surfaces; historical NEWS wording was retained as history:

```sh
rg -n -i "student.{0,80}(slope|intercept)|(?:slope|intercept).{0,80}student" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
rg -n "Student.*targeted random slopes|targeted Student-t random slopes|Student-t random-intercept SD|Student-t ordinary.*intercept.*SD" README.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/location-scale-scale.Rmd _pkgdown.yml
```

The README, roadmap, limitations, formula grammar, and pkgdown navigation did
not need changes for this family-specific addition.

## 9. What Did Not Go Smoothly

The first compiled test command loaded an older installed package and rejected
the formula before reaching current source. Installing this worktree into a
fresh isolated library resolved the fixture mismatch. HTML rendering was
unavailable in this environment, so the example was checked by executing its
chunks with knitr.

## 10. Known Residuals

This is point-recovery, likelihood, public-output, and refit-routing evidence,
not interval calibration. Correlated and structured Student-t SD targets,
random effects on `sigma` or `nu`, missing responses, and imputation remain
outside the slice. The Julia Student slope route exists, but a live R-to-Julia
Student slope parity test remains open. Programme gates G0-G8 remain open.

## 11. Team Learning

When a focused runner loads an installed package, verify that its library was
built from the current worktree before treating a formula refusal as a source
failure. Keep the independent likelihood oracle aligned with the latent
loading, including its squared contribution to curvature. The report checker
also needs to pass before a task note is described as complete.

## 12. Cross-Product Coverage

- Native TMB: complete-data univariate Student-t with one ordinary independent
  location slope and a coefficient-selected fixed-predictor SD formula is
  exercised for assembly, recovery, likelihood, predictions, simulation,
  storage, and refit routing.
- Julia fitting exists for a separate one-slope Student-t route, but this slice
  does NOT cover native-to-Julia bridge parity.
- Interval calibration, correlated blocks, structured effects, random effects
  on `sigma` or `nu`, missing-response routes, and the broader programme are
  not covered by this slice.
