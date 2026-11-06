# After Task: Binomial relatedness-matrix SD verification

## 1. Goal

Recheck the native Bernoulli `relmat()` SD-regression route, document its
current public behavior, and record the remaining Julia parity dependency.

## 2. Implemented

No model source changed. The existing native Binomial route fits an
intercept-only `relmat()` effect with `sd(id, level = "relmat") ~ z`. The
predictor must be constant within group. I added an independent synthetic
example to the predictor-dependent SD tutorial and updated the capability
inventory and acceptance evidence.

## 3a. Decisions and Rejected Alternatives

The Julia audit found no matching Binomial `relmat()` SD route in the paired
DRM.jl candidate. Its active task is working on CMR, and the relevant files
are dirty, so I made no edits in that repository. I asked its active owner to
identify the source owner and provide a handoff. This report does not claim
cross-engine parity.

## 4. Files Touched

- `vignettes/predictor-dependent-random-sd.Rmd`
- `docs/dev-log/general-sd-regression/inventory.md`
- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-20-binomial-relmat-sd-verification.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- This report

## 5. Checks Run

- Before the test, the estimated runtime was under 2 minutes.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e
  'devtools::test(filter = "binomial-relmat-sd")'`: 22 passed, 0 failed,
  0 warnings, 0 skips in 18.5 seconds. No live Julia tests ran.
- Source-loaded render of `vignettes/predictor-dependent-random-sd.Rmd` to
  `/private/tmp/predictor-dependent-random-sd-check-20261020-binom-relmat.html`:
  passed. Pandoc reported its existing deprecated `--mathjax` option.
- `git diff --check`: pending final readback.
- The programme ledger remains open; the Binomial `relmat()` cell is only one
  native row among many remaining family, provider, effect, and engine cells.

## 6. Tests of the Tests

The existing test uses a fixed seed and checks convergence, both log-SD
coefficients, the fitted group-SD surface, prediction, random-effect scaling,
marginal simulation, save/reload prediction, and equivalence to the
constant-SD fit. The passing result is a single-design recovery and workflow
check. It is not interval calibration.

## 7a. Issue Ledger

- Verified: the focused native Binomial `relmat()` test passes on the current
  worktree.
- Open: Julia `relmat()` parity and source ownership in the paired DRM.jl lane.
- Open: the remaining required capability rows and programme-wide checks.
- Deferred: 95% interval-coverage calibration, as specified by the active goal.

## 8. Consistency Audit

The tutorial example, candidate inventory, and G3/G4/G6 evidence identify this
as one native Bernoulli q1 `relmat()` intercept. The covariance retains the
supplied matrix scaling and is represented as `D K D`. The docs state that
Julia parity and other structured combinations remain unestablished.

## 9. What Did Not Go Smoothly

The lane preflight script first returned a shell parse error because it was
invoked through Python; rerunning it with Bash produced the expected
path-specific result. It found no missing carried refs for `R/drmTMB.R` or
`src/drmTMB.cpp` in the checked interval and many refs for `R/julia-bridge.R`.
No foreign-owned source was edited.

## 10. Known Residuals

No Julia `relmat()` fit ran. No cross-engine comparison, interval calibration,
profile/bootstrap refit, missing-data route, other provider, structured slope,
or broad recovery claim follows from this check. G3, G4, G6, G7, and G8 remain
open.

## 11. Team Learning

When one engine already has a structured SD test, check the paired backend's
provider dispatch and confirm file ownership before starting a parity port.
Keep the existing passing row useful by documenting its precise boundary.

## 12. Cross-Product Coverage

This verifies one native R/TMB Bernoulli `relmat()` intercept route and its
tutorial render. It does NOT cover Julia, other response families, other
structured providers, ordinary or correlated random effects, bivariate
models, calibrated intervals, or programme completion.

## 13. Prose Assessment

Style: 2/10, medium confidence; the report uses short concrete statements.
Genre/coverage: implementation after-task report, read in full. Evidence gates:
science = checked against the test and covariance statement; facts = test output
and current source; references = not applicable because no external citations
are used. Provenance: author self-review after the prose checker, version 2,
2026-10-20.
