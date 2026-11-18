# After Task: Binomial animal-plus-IID probit and cloglog SD bridge

## 1. Goal

Exercise predictor-dependent random-effect SDs for one animal intercept and one IID intercept through the R-to-Julia bridge under probit and complementary log-log links, with native TMB as a same-data comparator.

## 2. Implemented

The Julia Binomial SD fitter now admits this two-target combination for probit and cloglog and carries the link through its likelihood auxiliary data. The new opt-in bridge fixture uses independently simulated animal and IID effects with separate predictor-dependent SDs.

## 3a. Decisions and Rejected Alternatives

The extension is limited to the existing animal-plus-IID intercept layout. It does not generalize admission to other structured blocks or additional random-effect combinations. Existing logit behavior remains on its prior likelihood route.

## 4. Files Touched

- Julia candidate: `../general-sd-julia/src/binomial_sd_regression.jl`
- `tests/testthat/test-julia-binomial-animal-iid-nonlogit-sd-bridge.R`
- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/check-log.d/2026-10-26-binomial-animal-iid-nonlogit-bridge.md`
- This report.

## 5. Checks Run

- The opt-in focused R bridge test passed for probit and cloglog. It fits each synthetic dataset with TMB and Julia and checks convergence, point recovery for both SD slopes, formula-based group SD predictions, and log-likelihood agreement. A fresh source-bound rerun is recorded in `docs/dev-log/check-log.d/2026-10-26-binomial-animal-iid-nonlogit-bridge.md`.
- The existing logit animal-plus-IID live parity test passed with `NOT_CRAN=true` and both-engine opt-in enabled.
- The fit-free rerun passed with the opt-in live test skipped as expected.
- `git diff --check -- src/binomial_sd_regression.jl` passed in the paired Julia candidate.
- Julia source SHA-256: `7b77883ee26ae873dfde2963dc9f13710f02f8b02690e05e4f7c3a0b85f16945`.

## 6. Tests of the Tests

The fixtures construct the declared animal and IID latent effects separately and evaluate both links against the same observations in both engines. The checks are point recovery and output agreement; they do not test interval coverage.

## 7a. Issue Ledger

No issue was opened or changed.

## 8. Consistency Audit

The test uses group-constant predictors for each SD target. Probit and cloglog likelihood dispatch receives the link explicitly in the animal-plus-IID fitter. The logit path retains its existing auxiliary representation.

## 9. What Did Not Go Smoothly

The first live run showed that the admission check counted formula targets incorrectly by requiring one SD part for a two-target model. The check was corrected to require two parts, and the focused live tests then passed.

## 10. Known Residuals

This evidence does not cover probit/cloglog phylogenetic animal-plus-IID combinations, other structured blocks, bivariate responses, other families, profile/bootstrap output integrity, or calibrated uncertainty. Programme gates G3, G4, G6, G7, and G8 remain open. Coverage calibration is separately deferred by the approved goal update.

## 11. Team Learning

For link-specific structured likelihood routes, admission tests should be paired with a same-data likelihood comparison so that an admitted formula cannot silently fall through to the default link.

## 12. Cross-Product Coverage

This slice covers R-to-TMB and R-to-Julia animal-plus-IID Bernoulli intercepts with predictor-dependent SDs under probit and cloglog, plus a logit regression check. It does NOT cover animal slopes, phylogenetic or spatial terms, other correlated blocks, bivariate models, missing-data routes, interval calibration, or any non-Bernoulli response family. The full capability ledger remains incomplete.
