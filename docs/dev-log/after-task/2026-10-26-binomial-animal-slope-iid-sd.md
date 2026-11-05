# After Task: Binomial animal-slope plus IID-intercept SD regression

## 1. Goal

Extend native Binomial predictor-dependent random-effect SD regression to one animal random slope plus one ordinary IID random intercept, each with its own SD formula.

## 2. Implemented

The native R builder now admits one unlabelled q1 animal term, whether intercept-only or slope-only, with one ordinary unlabelled IID intercept. Complete responses remain required. The existing model type 18 assembly combines the structured animal field with ordinary IID terms. The updated fixture and tests check the slope loading and recover both predictor-dependent SD coefficients.

## 3a. Decisions and Rejected Alternatives

This slice extends the admission boundary only for a single animal q1 term plus a single ordinary intercept. It preserves the existing TMB likelihood and parameterization. Animal q2 blocks, multiple ordinary terms, labelled structures, and incomplete responses remain refused.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-binomial-animal-iid-sd-regression.R`
- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/check-log.d/2026-10-26-binomial-animal-slope-iid-sd.md`
- This report.

## 5. Checks Run

- The focused native test file passed, including design assembly, separate animal/IID SD recovery, predictor-specific SD outputs, and save/reload checks.
- `phylo_mu_value` from the shared structured TMB payload matched the animal slope predictor `x` row by row.
- `git diff --check` passed for the scoped source, test, and evidence files.
- The test run exercised native TMB only. Julia admission and parity for animal-slope plus IID-intercept models are not implemented in this slice.

## 6. Tests of the Tests

The synthetic fixture draws an animal slope from the supplied relationship matrix and scales it by `exp(-0.7 + 0.45 z_animal)`. It adds an independent IID site intercept scaled by `exp(-0.8 + 0.45 z_iid)`. The fit checks convergence, both SD-slope point estimates, separate group-level prediction lengths, and save/reload target retention. These checks are not interval calibration.

## 7a. Issue Ledger

No issue was opened or changed.

## 8. Consistency Audit

The animal term is `animal(0 + x | id, A = A)` and the ordinary term is `(1 | site)`. The animal SD predictor is constant within animal and the IID SD predictor is constant within site. Each has a separately named coefficient block and prediction target.

## 9. What Did Not Go Smoothly

The first assembly assertions looked for `phylo_mu_value` at the outer `make_tmb_data()` wrapper. The shared structured payload is returned by `structured_mu_tmb_data()`, so the assertions were corrected to inspect that exact payload. The focused test then passed.

## 10. Known Residuals

This evidence covers native TMB only. Julia animal-slope plus IID-intercept parity, non-logit links, `Ainv`, pedigree input, profiles/bootstrap, marginal simulation, bivariate responses, and interval calibration remain open. Programme gates G3, G4, G6, G7, and G8 remain open. Coverage calibration is deferred to the separate follow-up.

## 11. Team Learning

When the TMB data interface uses a helper to build a structured block, assembly tests should inspect that shared payload directly instead of assuming every field is copied onto the outer test wrapper.

## 12. Cross-Product Coverage

This slice covers a native Binomial animal slope plus one IID intercept with separate predictor-dependent SD formulas under logit. It does NOT cover Julia parity, non-logit links, animal q2 blocks, multiple IID terms, other structured providers, other response families, or calibrated intervals. The cross-engine capability ledger remains open.
