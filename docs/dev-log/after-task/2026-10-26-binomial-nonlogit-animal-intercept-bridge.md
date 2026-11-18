# After Task: Binomial probit and cloglog animal-intercept SD bridge

## 1. Goal

Add live recovery evidence for predictor-dependent animal-intercept SDs under the probit and complementary log-log Binomial links through the R-to-Julia bridge, compared with native TMB.

## 2. Implemented

Added independent seeded synthetic fixtures to the opt-in live bridge test. Each link uses an animal covariance `D A D`, with `log(SD) = alpha_0 + alpha_z z`, group-constant randomized `z`, and repeated Bernoulli observations. The tests check the structured family tag, convergence, finite and named SD coefficients, predictor-slope recovery, likelihood agreement, and predicted group SDs.

## 3a. Decisions and Rejected Alternatives

The source implementation was unchanged because the current bridge route already admits this exact shape. The new tests target the animal intercept only; they do not broaden the source gate or combine animal and IID terms.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-nonlogit-structured-sd-bridge.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-26-binomial-nonlogit-animal-intercept.md`
- `.unlazy/general-sd-regression/GATES.md`
- This report.

## 5. Checks Run

- Live command: `DRMTMB_JULIA_TESTS=true DRMODELS_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_HOME='/Users/z3437171/.juliaup/bin' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=4 Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-julia-binomial-nonlogit-structured-sd-bridge.R", reporter = "summary")'` passed three live test blocks, including the new probit and cloglog animal-intercept cases. JuliaCall used Julia 1.10.0.
- Fit-free rerun of the focused bridge file passed; its three live test blocks were skipped as expected without opt-in.
- The live run exercises six native/Julia fits across animal slopes, animal intercepts, and relmat intercepts. It is point-recovery and output evidence, not interval calibration.
- `git diff --check` passed for the touched files.

## 6. Tests of the Tests

The tests use independently simulated latent animal effects from the declared `D A D` covariance and separate seeds for each link. They check the returned scale against the fitted predictor formula and compare predictions and likelihoods across engines. No coverage claims are made.

## 7a. Issue Ledger

No issue was opened or changed.

## 8. Consistency Audit

The fixed predictor `z` is constant within each animal. Both engines receive the same unit-diagonal AR(1) matrix `A`, group ordering, response data, and animal-intercept formula. The SD is interpreted on the link scale for each Binomial link.

## 9. What Did Not Go Smoothly

The shared lane-lease registry was slow and did not return a usable lease receipt during this continuation. The required path preflight found no divergent ref work on the untracked test file, and no other lane had edits in that file. The implementation remained test-only; the active documentation lane's bridge source was not touched.

## 10. Known Residuals

These fixtures do not establish interval calibration, all structured Bernoulli routes, probit/cloglog phylogenetic parity across both engines, multiple simultaneous structured effects, Julia inference API parity, or support for other response families. Programme gates G3, G4, G5, G6, G7, and G8 remain open.

## 11. Team Learning

For a structured non-logit bridge, test the R family tag and a live same-data fit: a route can be admitted by formula shape while still reaching the wrong likelihood if its link is lost in bridge assembly.

## 12. Cross-Product Coverage

The added test covers R-to-Julia and R-to-TMB animal-intercept fits for probit and cloglog with one supplied relatedness matrix. It does NOT cover ordinary IID effects, animal-plus-IID combinations, relmat in this slice, phylogenetic or spatial effects, bivariate models, missing-data or REML routes, simulation or refitting outputs, interval calibration, or other families. This evidence leaves the general capability ledger incomplete.
