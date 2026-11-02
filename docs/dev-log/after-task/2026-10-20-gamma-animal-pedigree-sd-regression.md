# Gamma animal-pedigree random-effect SD regression

## 1. Goal

Implement and document one additional cell in the general predictor-dependent
random-effect SD programme: a native TMB Gamma model with one animal-model
location intercept, pedigree/covariance/precision input, and a group-level
predictor for the latent SD. The programme goal remains open.

## 2. Implemented

The Gamma builder now admits the animal q1 intercept with pedigree, covariance,
or precision input when a direct animal SD formula is present. The TMB branch
scales the animal effect by the predictor-dependent SD while retaining the
existing relationship precision and diagonal scaling. The constant-SD form
remains on the same likelihood path. The public synthetic example uses an
explicit supplied relationship matrix; the regression test exercises pedigree
conversion and precision.

The test checks that the fitted sparse precision agrees with the reordered
dense covariance inverse, the seeded SD slope is recovered within a declared
point-check tolerance, predictions are keyed to animal names, and a constant
SD formula matches the existing constant-SD fit's likelihood. It also verifies
matching likelihoods when the relationship is passed as a pedigree, covariance
matrix, or inverse-covariance matrix.

## 3a. Decisions and Rejected Alternatives

This slice uses the existing animal marker and SD selector. It does not add
new syntax or normalize the supplied covariance. The example constructs a
small positive-definite relationship matrix directly, rather than calling an
internal pedigree helper from a user-facing vignette. The regression fixture
retains pedigree input so it checks the pedigree precision builder.

## 4. Files Touched

- `R/drmTMB.R` and `src/drmTMB.cpp`: Gamma builder, parameter mapping and
  animal-field likelihood.
- `tests/testthat/test-gamma-animal-pedigree-sd-regression.R`: synthetic
  precision, recovery, prediction, and equivalence checks.
- `vignettes/predictor-dependent-random-sd.Rmd`, `NEWS.md`, and the
  formula, likelihood, random-effect SD, worked-example, and non-Gaussian map
  design pages: example and exact capability boundary.
- `docs/dev-log/known-limitations.md` and
  `docs/dev-log/general-sd-regression/inventory.md`: candidate status.
- `.unlazy/general-sd-regression/GATES.md`,
  `LOOP/lanes/general-sd-regression/arcs.md`,
  `LOOP/lanes/general-sd-regression/checkpoint.md`, and
  `docs/dev-log/check-log.md`: partial evidence and continuation state.

## 5. Checks Run

- `Rscript -e 'parse(file="R/drmTMB.R")'`: passed.
- `Rscript -e 'devtools::test(filter = "gamma-animal-pedigree-sd-regression")'`:
  14 passed, no failures, warnings, or skips.
- `Rscript -e 'devtools::test(filter = "gamma-sd|gamma-animal-pedigree|lognormal.*sd")'`:
  110 passed, no failures or warnings, and 2 skips in 89.2 seconds. Both skips
  are live Julia tests because no Julia engine was configured.
- The source-loaded render of
  `vignettes/predictor-dependent-random-sd.Rmd` succeeded. Pandoc reported
  only its deprecated `--mathjax` option.
- `pkgdown::check_pkgdown()`: no problems found; Pandoc reported deprecated
  `--mathml` options.
- Scoped `git diff --check` across the Gamma implementation, tests, and
  documentation: passed.
- The report structure check passed. The higher-level closeout check still
  reports unmet programme gates, which remain open for this partial slice.
- `graft build`: refreshed 29,646 nodes and 58,179 edges.
- Independent static review found the TMB covariance scaling and parameter
  offsets consistent with this q1 route.

## 6. Tests of the Tests

The focused test failed before the builder and TMB changes because Gamma
rejected the animal SD target. An initial run after the implementation exposed
an incorrect coefficient offset through both slope recovery and likelihood
equivalence. After using the common structured-SD offset helper, the original
10 assertions passed. An added covariance-input smoke caught the parser's
requirement that matrix arguments be object names; binding the matrices before
the formulas fixed the fixture. The expanded test passes 14 assertions. It is
a single seeded point-recovery case, not a repeated recovery study.

## 7a. Issue Ledger

- Done: native Gamma q1 animal fitting for pedigree, covariance, and precision
  input in the tested complete-data route.
- Done: sparse precision ordering, one slope point check, named SD prediction,
  and constant-SD likelihood equivalence.
- Open: Julia implementation and live Julia parity.
- Open: other Gamma providers, effect shapes, predictors, and combined
  structured layouts.
- Deferred: confidence-interval coverage and false-positive calibration.

## 8. Consistency Audit

The formula reference, likelihood design, random-effect SD design, vignette,
NEWS, known-limitations note, candidate inventory, programme gate, check log,
and recovery checkpoint describe the same route and the same evidence
boundary. No claim of calibrated intervals or Julia support was added. G3-G8
and the overall programme remain open; G5 coverage calibration stays deferred.

## 9. What Did Not Go Smoothly

The first vignette render found that the example still referred to a pedigree
object after its generator was removed. The example was corrected to use the
constructed relationship matrix and then rendered successfully. The first
likelihood test also caught the SD coefficient offset error noted above.

## 10. Known Residuals

This test does not cover saving and reloading, marginal simulation, profile or
bootstrap refits, interval calibration, live Julia, Gamma animal slopes, or
other providers. No full package test, Totoro campaign, or DRAC job was run
for this slice. A separate whitespace finding remains in
`tests/testthat/test-binomial-sd-integration.R`, outside the scoped Gamma
changes.

## 11. Team Learning

For structured SD regressions, use the shared target-offset helper rather than
inferring an offset from a placeholder ordinary-SD design. Keep the test DGP
ordering distinct from the model factor ordering so the precision alignment is
actually exercised.

## 12. Cross-Product Coverage

This is native R/TMB evidence only. It does NOT cover Julia parity, the DRM.jl
implementation, calibrated uncertainty, the remaining capability rows, or
completion of the general SD-regression programme.

Memory receipt: the local route helper found no LOAD-FIRST manifest for this
worktree or its parent checkout. The brain note
`20260715-074123-drmtmb-sd-random-effect-hierarchy` was retrieved directly;
its fixed-predictor and latent-target boundary informed the formula scope.
Golden Set: not run. The test exercises the new animal-pedigree route and the
initial offset error this implementation introduced; no repository Golden Set
for this specific route was identified.
