# After Task: Native zero-truncated NB2 random-slope SD regression

## 1. Goal

Enable a fixed-predictor model for the SD of one ordinary independent location
slope in native zero-truncated NB2, and check that the new formula retains the
existing constant-SD fit.

## 2. Implemented

The native builder admits one selected independent numeric `mu` slope with a
group-level direct-SD formula on complete responses and fixed-effect `sigma`.
For group (g), the coefficient has distribution
\(b_g \sim N(0, \tau_g^2)\), where \(\log \tau_g = W_g\alpha\). The
predictor rows in \(W_g\) must be constant within the grouping factor. The
ordinary zero-truncated model has no hurdle formula; its likelihood remains
the positive-count NB2 likelihood. The public example uses synthetic generic
variables only.

## 3. Mathematical Contract

The SD formula targets the selected random coefficient, not residual or NB2
overdispersion `sigma`. The random slope is applied to the `mu` linear
predictor before the positive-count truncation likelihood is evaluated. The
implementation preserves the existing random-effect and truncation
parameterizations. A constant SD formula is equivalent to the legacy
constant-SD fit within the test's numerical tolerance.

## 3a. Decisions and Rejected Alternatives

This slice adds a selected independent slope, not a new formula interface or
covariance family. It leaves the existing truncation and SD parameter maps
unchanged. Coverage calibration and Julia parity remain later validation work.

## 4. Files Touched

- `R/drmTMB.R`: admits one selected independent ordinary `mu` slope for direct
  SD regression and maps that target to its group-level SD design. The existing
  TMB truncated-count branch consumes the mapped coefficient SD; no new C++
  likelihood change was needed for this slice.
- `tests/testthat/test-truncated-nbinom2-sd-regression.R`
- `tests/testthat/test-truncated-nbinom2-sd-integration.R`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `vignettes/formula-grammar.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-21-truncated-nbinom2-slope-sd.md`
- `docs/dev-log/after-task/2026-10-21-truncated-nbinom2-slope-sd.md`
- `docs/dev-log/after-task/2026-10-21-truncated-nbinom2-slope-sd.assessment.json`

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "truncated-nbinom2-sd-regression")'`:
  20 passed, 0 failed, 0 warnings, 0 skipped.
- `Rscript -e 'devtools::test(filter = "truncated-nbinom2-sd-integration")'`:
  16 passed, 0 failed, 0 warnings, 0 skipped in 81.0 seconds.
- A read-only mathematical review found no wiring defect. It independently
  traced the selected group SD into the slope contribution before the
  zero-truncated likelihood.
- GitHub search for `repo:itchyshin/drmTMB truncated NB2 random effect SD
  predictor-dependent slope` returned no open issue.
- The formula-grammar vignette rendered successfully; only the existing
  deprecated `--mathjax` warning appeared.
- `pkgdown::check_pkgdown()` found no problems; it reported existing Pandoc
  `--mathml` deprecation warnings.
- `slop_check.py` found 0 issues in this report. The after-task structure
  checker and exact-draft assessment record are listed after they run.

## 6. Tests of the Tests

The assembly test checks the selected coefficient, groupwise SD design, and
unsupported-term fences. The integration fixture uses a seeded synthetic
data-generating process and independently integrates each group's
zero-truncated NB2 likelihood over a scalar standard-normal effect. Reversing
the group-SD indexing must change the oracle result. A separate constant-SD
fit checks backward numerical equivalence. The broad five-log-likelihood-unit
Laplace/oracle threshold is a sanity check only; the one-seed fixture does not
establish repeated-recovery performance.

## 7a. Issue Ledger

No matching open GitHub issue was found. No issue was created or changed.

## 8. Consistency Audit

Formula grammar, the user-facing formula table, NEWS, the non-Gaussian family
map, and the validation-debt register now distinguish ordinary truncated-NB2
slope SD regression from the separate hurdle-intercept SD route. The support
claim is limited to complete responses, one selected ordinary slope, and
fixed-effect `sigma`. Julia parity and interval calibration are stated as
unverified. Exact stale-wording searches are listed in the check fragment.

## 9. What Did Not Go Smoothly

Lane preflight found an active lease on the shared native builder and extensive
historical cross-reference work on the documentation files. I left the builder
untouched in this slice and reviewed the relevant overlapping documentation
hunks before making narrow wording changes.

## 10. Known Residuals

This is one native point-recovery fixture, not repeated recovery or calibrated
uncertainty. Julia parity is not tested. Correlated slopes, structured effects,
missing responses, random NB2 `sigma`, hurdle-side slopes, and broader family
combinations remain outside this slice.

## 11. Team Learning

For a selected random-slope SD, the group-to-coefficient mapping deserves its
own negative control. Keep the quadrature result labelled as a sanity check
when its tolerance is broad, even when the indexing control is sensitive.

## 12. Cross-Product Coverage

This slice covers native TMB only and does NOT cover Julia parity, interval
coverage, hurdle-side slope SDs, structured or correlated slopes, missing
responses, or other family/effect combinations.

## 13. Next Actions

Continue the approved implementation-first programme one bounded family/effect
cell at a time. Keep interval-coverage calibration deferred and do not promote
coverage or cross-engine claims from this result.
