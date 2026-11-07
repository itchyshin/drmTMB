# After Task: Student-t SD regression through the Julia bridge

## 1. Goal

Admit the already implemented Student-t ordinary random-intercept and
independent-slope SD routes through the R-to-Julia bridge where they match the
native TMB route, and verify both engines on independent synthetic data.

## 2. Implemented

The fixed-effects-only family fence now admits the narrow Student-t SD cell:
one ordinary location intercept or one independent numeric location slope, a
single matching `sd()` target, and fixed-intercept `sigma` and `nu`. Correlated
blocks, structured terms, random effects on `sigma` or `nu`, and unmatched
targets still reach the existing refusal path. Live same-data TMB/Julia tests
now cover both the intercept and slope target shapes, group-level and row-level
SD predictions, and save/reload for the slope route.

## 3a. Decisions and Rejected Alternatives

- Kept the family registry's fixed-effect declaration and made a formula-shape
  exception inside its existing random-effect fence. This preserves the
  conservative default for other registry families.
- Required a one-to-one match between the ordinary random-effect grouping and
  its SD target. The slope route also requires its explicit coefficient
  selector.
- Kept `sigma` and `nu` at intercept-only fixed effects, matching the Julia
  Student-t SD fitter exercised here.
- Treated the comparisons as point recovery and output parity, not uncertainty
  calibration.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-student-sd.R`
- `vignettes/location-scale-scale.Rmd`
- `docs/design/02-family-registry.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/general-sd-regression/native-family-wave-plan.md`
- `vignettes/julia-engine.Rmd`
- `NEWS.md`
- `.unlazy/general-sd-regression/gates/student-slope-julia-bridge.md`
- `docs/dev-log/check-log.d/2026-10-18-student-slope-julia-bridge.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-18-student-slope-julia-bridge.md`

## 5. Checks Run

- The first live slope bridge test failed at the existing fixed-effects-only
  guard, confirming the precise admission gap.
- The source-assembly run passed 9 bridge-admission expectations. Its two live
  tests skipped as expected because that isolated run did not set a Julia path.
- With `DRMTMB_JULIA_TESTS=true` and the paired DRM.jl worktree, the focused
  live suite passed 32 expectations in 74.1 seconds. Both intercept and slope
  tests ran, with zero failures, warnings, or skips.
- The existing `julia-bridge` filter passed 208 expectations with zero
  failures. It emitted two pre-existing `beta()` deprecation warnings and
  skipped three live tests because that regression check intentionally ran
  without `DRM_JL_PATH`.
- `pkgdown::check_pkgdown()` and `git diff --check` are recorded in the final
  closeout after the documentation updates.

## 6. Tests of the Tests

The first live run failed before Julia initialization with the family fence's
fixed-effects-only error. The test passed after the exact Student formula
exception was added. Source tests cover the admitted slope and intercept,
continued refusal without an SD target, random effects on `sigma`, a correlated
intercept-slope block, a mismatched grouping target, and multiple SD targets.
The live tests independently generate complete Student-t data and fit the same
rows through native TMB and Julia. They compare recovered SD coefficients and
check that group and row predictions retain the target identity.

## 7a. Issue Ledger

The issue tracker was searched for an existing Student-t Julia SD-regression
bridge issue. No issue was changed; the live result is recorded here and in the
check log.

## 8. Consistency Audit

The Student-t bridge exception matches the formula selector, native Student-t
target, Julia SD block, and public R coefficient and prediction labels. The
family guide, model-scale guide, wave plan, vignette, and NEWS now report the
same support boundary and distinguish point parity from calibration. The
following status surfaces were checked for conflicting Student bridge claims:

```sh
rg -n -i "student.{0,100}(random|sd|slope|intercept|fixed.effect)|(?:random|sd|slope|intercept).{0,100}student" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/18-random-effect-scale-models.md vignettes/formula-grammar.Rmd vignettes/location-scale-scale.Rmd vignettes/julia-engine.Rmd _pkgdown.yml
rg -n "Student-t.*(bridge parity|fixed.effect.only|intercept focused)|Julia.*Student.*(not yet|separate)" docs/design/02-family-registry.md docs/design/18-random-effect-scale-models.md docs/dev-log/general-sd-regression/native-family-wave-plan.md vignettes/location-scale-scale.Rmd NEWS.md
```

The README, roadmap, formula grammar, known-limitations page, and pkgdown menu
needed no change. The Julia-engine guide's family table and fixed-effect-only
boundary were updated because they previously classified Student-t as
fixed-effect-only.

## 9. What Did Not Go Smoothly

The first broader source-assembly attempt for `test-julia-bridge.R` loaded a
different pinned checkout and stopped at an older selected-target parser. A
normal `devtools::test(filter = "julia-bridge")` run from the current worktree
passed the relevant source tests, so the pinned-runner failure was not treated
as current-worktree evidence.

## 10. Known Residuals

The R bridge comparison covers one synthetic design per target, not repeated
sampling or calibration. The Student exception admits only the exact ordinary
scalar formulas checked here. Correlated and structured effects, random
`sigma` or `nu`, missing responses, imputation, and other Student endpoints
remain outside this route. G0-G8 for the wider SD-regression programme remain
open.

## 11. Team Learning

When extending a family already listed as fixed-effects-only, preserve that
default and make the positive formula shape explicit. A paired live fit can
reveal a bridge admission gap that a Julia-only model test cannot expose.

## 12. Cross-Product Coverage

- Student-t ordinary random intercept SD regression: native TMB fitting and
  Julia fitting are exercised; this task adds formula-level Julia bridge
  admission and cross-engine point comparison for an independent slope.
- Student-t ordinary independent random-slope SD regression: same-data native
  TMB and Julia fits, coefficient comparison, group and row SD predictions,
  and Julia save/reload are tested.
- This task does NOT cover interval calibration, correlated or structured SD
  targets, random `sigma` or `nu`, missing responses, imputation, or other
  families and endpoints.
