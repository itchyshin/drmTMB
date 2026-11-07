# After Task: Julia ZeroOneBeta ordinary direct-SD evidence

## 1. Goal

Verify and source-bind the narrow Julia ZeroOneBeta random-effect SD routes for one ordinary location intercept and one selected independent numeric location slope.

## 2. Implemented

The paired Julia development candidate fits complete-response ZeroOneBeta models with `sd(id) ~ z` for one ordinary `mu` intercept, or `sd(id, coef = "x") ~ z` for one independent numeric `mu` slope. Both keep `sigma`, `zoi`, and `coi` fixed at intercepts. The exact required rows now have separate unreviewed receipts.

## 3. Mathematical Contract

For the tested coefficient, the group-level SD is `exp(W_g alpha)`. The coefficient enters the ZeroOneBeta latent location predictor. This slice does not add random effects to `sigma`, `zoi`, or `coi` and does not change the family’s boundary-mass parameterization.

## 3a. Decisions and Rejected Alternatives

The two fixtures are recorded as `focused_test` evidence, not broad engine parity or interval calibration. The selected-slope route stays separate from the intercept route because its formula selector identifies a different latent coefficient.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/zeroonebeta-julia-sd-20261022/` contains the source manifest, test output, and receipt.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` links the exact Julia intercept and numeric-slope rows.
- `docs/dev-log/general-sd-regression/inventory.md`, `vignettes/julia-engine.Rmd`, and `NEWS.md` state the candidate route and boundary.
- `.unlazy/general-sd-regression/GATES.md`, `docs/dev-log/check-log.md`, and this report record partial evidence.

## 5. Checks Run

- The focused test `devtools::test(filter = "^julia-zero-one-beta-sd$", reporter = "summary", stop_on_failure = TRUE)` passed 35 assertions with two live Julia fits and no failures, warnings, or skips.
- The run used R 4.6.0, TMB 1.9.21, Julia 1.10.0, drmTMB candidate HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`, and DRM.jl candidate HEAD `70dbf564eb670144c63c08f61ea099084d95add2`.
- Reconciliation passed for 19,118 candidate rows, 18 linked rows, 19,100 unlinked rows, and 19 evidence records.
- A read-only GitHub issue search returned only an unrelated test-sweep issue. No issue was opened, commented on, or closed.

## 6. Tests of the Tests

The admission checks reject unselected or mismatched slopes, wrong groups, structured terms, and random effects on the other distributional parameters. The two synthetic bridge fits check convergence, SD-predictor recovery direction, coefficient names, group SDs, and prediction output. The intercept fixture also checks save/reload. The tolerances are point-fit checks and do not measure interval coverage.

## 7a. Issue Ledger

The read-only search for an open ZeroOneBeta Julia SD issue found no directly matching issue. The returned general test-sweep issue was unrelated. No issue was changed.

## 8. Consistency Audit

The bridge route, paired Julia fitter, formula grammar, package NEWS, and Julia engine capability table describe complete-response `mu` intercept and selected independent numeric slope routes with fixed `sigma`, `zoi`, and `coi`. The inventory now distinguishes them from unsupported Julia families and broader ZeroOneBeta random-effect forms. Evidence records remain unreviewed.

## 9. What Did Not Go Smoothly

The first evidence-map read showed that the guide still grouped ZeroOneBeta under “fixed effects only,” despite the fitted candidate route. I corrected the family table to state the exception and its limits. The rerun completed without an environment failure using the existing temporary Julia depot.

## 11. Team Learning

When a family has one narrow candidate route, the main family table must name that exception so its broad “fixed effects only” label does not contradict the actual fitter and bridge.

## 10. Known Residuals

This covers two complete-response ordinary `mu` targets in paired development candidates. It does not establish exact likelihood equality, profile or bootstrap behavior for these routes, interval calibration, structured or correlated effects, missing responses, other endpoints, or shared/released DRM.jl support. Programme gates G0, G1, G3, G4, G6, G7, and G8 remain open; G5 calibration is deferred.

## Next Actions

Render the updated Julia engine guide, then continue through the unresolved required families and effect-provider rows.

## 12. Cross-Product Coverage

This covers complete-response Julia ZeroOneBeta intercept and selected independent slope SD fits through the drmTMB bridge using the paired local development checkout. It does NOT cover structured or correlated terms, missing responses, other distributional parameters, interval calibration, or shared/released DRM.jl.
