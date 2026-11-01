# After Task: Tweedie related-matrix SD slice and skew-normal repair

## 1. Goal

Verify and document a native Tweedie related-matrix location-intercept SD
route, and repair the skew-normal ordinary-SD builder regression exposed by
rendering the guide.

## 2. Implemented

The Tweedie synthetic test fixture retains the group-level predictor needed
for checking named group SD predictions and row-expanded `predict_parameters()`
output. The predictor-dependent SD vignette includes a synthetic
relatedness-matrix intercept example. The skew-normal builder no longer tries
to build a structured mean effect from an undefined term; structured SD
formulas remain rejected for that family.

For the tested Tweedie route, `log(s_i) = alpha_0 + alpha_1 z_i` and
`Cov(b) = D K D`, where `D = diag(s_i)`. The fitted `s_i` multiplies the
supplied covariance, so the marginal SD is `s_i * sqrt(K[i, i])`. The example
holds Tweedie `sigma` and `nu` fixed and requires complete responses.

## 3a. Decisions and Rejected Alternatives

I kept this as a native q=1 related-matrix intercept example. I did not claim
Julia parity or edit shared capability and grammar pages while their owners'
changes were active. The rerun was treated as regression evidence, not as a
new simulation campaign. Assumption: the current focused test remains the
right regression check for this slice; a changed DGP or expanded target would
need its own independent test design.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-tweedie-relmat-sd-regression.R`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `docs/dev-log/check-log.d/2026-10-22-tweedie-relmat-sd-regression.md`
- `docs/dev-log/after-task/2026-10-22-tweedie-relmat-sd-regression.md`

## 5. Checks Run

- `devtools::test(filter = "tweedie-relmat-sd-regression")` passed 12
  expectations on the current rerun in 7 seconds, with no failures, warnings,
  or skips. Earlier focused runs also passed the Tweedie and skew-normal
  filters together, 29 expectations total.
- The current-source predictor-dependent SD vignette rendered and
  `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site()` passed its metadata checks but could not resolve
  cdnjs to download `headroom.min.js`.
- `slop_check.py` reported no findings for both current records. The target
  files had no trailing whitespace. A broad `git diff --check` surfaced a
  blank line at EOF in the unrelated, dirty
  `tests/testthat/test-binomial-sd-integration.R`; that file was left alone.
- `Rscript ~/shinichi-brain/tools/check-after-task.R` is the required report
  validator; the updated report is checked with the exact path below.

## 6. Tests of the Tests

The Tweedie test compares group predictions with the fitted SD formula at the
known synthetic predictors and checks the observation-level expansion. The
focused Tweedie test passed all 12 expectations. Earlier, the Tweedie fixture
test failed when its helper omitted the group predictor, and the skew-normal
tests failed on the undefined structured-term reference before the respective
repairs.

## 7a. Issue Ledger

No matching open GitHub issue was found for Tweedie random-effect SD in the
bounded search. No issue was opened or changed. The full capability map and
the Julia route remain unresolved in the parent programme.

## 8. Consistency Audit

The rendered example uses `relmat()` with
`sd(id, level = "relmat") ~ z` and describes the covariance multiplier
interpretation. The audit searched README, NEWS, the roadmap, known limitations,
the formula grammar, and the formula-grammar vignette for related Tweedie and
skew-normal claims. It found shared status statements requiring later
reconciliation. The central capability pages and grammar were left untouched
because of active overlapping work.

Memory receipt: I loaded the drmTMB `LOAD-FIRST` manifest with
`python3 ~/shinichi-brain/tools/route.py drmTMB`, read the after-task protocol,
and queried the brain for the prior SD hierarchy decision. Lane preflight and
the local diffs shaped the decision to avoid shared Julia and capability
paths. Golden Set: not in scope because this slice did not exercise a known
registered failure class.

## 9. What Did Not Go Smoothly

The first vignette render loaded an older installed checkout. Loading the
current source exposed the undefined skew-normal term; fixing it allowed the
ordinary SD tests to run. The full site build stopped on a network DNS failure.
The required report checker also exposed that the earlier report used obsolete
section headings; this version follows the current protocol.

## 10. Known Residuals

This slice establishes one complete-data native TMB Tweedie q=1 related-matrix
location intercept. It does not establish Julia parity, interval calibration,
other providers or effect shapes, or the programme-wide target universe. The
skew-normal change has assembly-level regression evidence only; it does not
evaluate skew-normal recovery or inference. The repository-wide diff check
still reports the unrelated trailing blank line noted above.

## 11. Team Learning

For source-loaded vignette checks, explicitly load the current worktree. Keep
the generating group-level SD predictors in test fixtures so predictions can
be checked against their known design. Run the current report validator before
carrying forward an older after-task note.

## 12. Cross-Product Coverage

- Native TMB, Tweedie, q=1 `relmat()` location intercept, complete responses:
  focused recovery and output test ✓.
- Julia Tweedie, other Tweedie providers, random slopes, other endpoints,
  interval calibration, and programme-wide target coverage: Does NOT cover.
- Skew-normal ordinary SD assembly: focused regression test ✓. Structured
  skew-normal SD, new recovery evidence, and inferential calibration: Does NOT
  cover.
