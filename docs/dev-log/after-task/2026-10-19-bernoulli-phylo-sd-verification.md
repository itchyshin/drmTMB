# After Task: Bernoulli Phylogenetic SD Verification

## 1. Goal

Verify the current candidate's native Bernoulli phylogenetic SD-regression recovery path and its Julia-bridge extraction/prediction outputs on independent synthetic fixtures.

## 2. Implemented

No model code changed. The native test passed with the true varying-SD fit, constant-SD fit, and scalar baseline; the R-side Julia test passed its synthetic target-resolution, coefficient-extraction, and reordered-new-data prediction checks. The first live Julia bridge case was skipped because no Julia engine path was configured. A 2026-10-20 follow-up exercised one live Julia fit on the paired candidate.

## 3a. Decisions and Rejected Alternatives

The constant-SD comparison was retained as a necessary reduction check. The native single-seed recovery result is not treated as interval calibration or broad cross-engine parity.

## 4. Files Touched

The tested model uses
\[
u \sim N(0,K),\qquad b_g=\tau_g u_g,\qquad
\log\tau_g=\alpha_0+\alpha_1 z_g,
\]
so the structured random-effect covariance is \(DKD\) using the existing tree covariance \(K\). This verification did not normalize the tree or alter the covariance contract.

## Files Changed

- `docs/dev-log/check-log.md` records the earlier native and synthetic-output checks; the current live rerun is in the per-slice check log below.
- `docs/dev-log/check-log.d/2026-10-20-bernoulli-phylo-sd-live-julia.md` records the live bridge rerun.
- `LOOP/lanes/general-sd-regression/checkpoint.md` records the current Bernoulli phylogenetic checkpoint.
- This report and its separate style/factual assessment are retained under `docs/dev-log/after-task/`.

## 5. Checks Run

- `NOT_CRAN=true OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-binomial-phylo-sd-regression.R")'` passed 12 assertions with zero failures, warnings, or skips. It fitted three models and checked positive slope recovery, group prediction, and constant-SD equivalence to the scalar baseline.
- `R_PROFILE_USER=/dev/null Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-binomial-phylo-sd.R")'` passed six synthetic assertions and skipped one live Julia case because `DRM_JL_PATH` and `DRMODELS_JL_PATH` were unset.
- The first native command omitted `NOT_CRAN=true` and skipped the test through `skip_on_cran()`; the command above reran it with the intended local-test setting.
- On 2026-10-20, `DRMODELS_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRMTMB_JULIA_TESTS=true JULIA_PROJECT='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_DEPOT_PATH='/private/tmp/codex-drmtmb-julia-depot:/Users/z3437171/.julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-binomial-phylo-sd", reporter = "summary")'` exited 0. The bridge summary reported one live Julia test and confirmed the bridge glue ran. Both fits converged; the test compared SD coefficients, log likelihood, predicted group SDs, and raw-tree scale correction on the same synthetic data. An `Optim` precompile-cache warning and the expected raw branch-length-scale warning appeared; neither stopped the test.
- Direct Julia check: `JULIA_DEPOT_PATH='/private/tmp/codex-drmtmb-julia-depot:/Users/z3437171/.julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'include("test/test_binomial_phylo_sd_regression.jl")'` passed 21/21 assertions.

## 5a. Reproducibility Receipt

The bridge rerun used drmTMB candidate HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1` and DRM.jl candidate HEAD `70dbf564eb670144c63c08f61ea099084d95add2`. The source and test files were dirty candidates; these SHA-256 values identify the exact files exercised:

- `tests/testthat/test-julia-binomial-phylo-sd.R`: `6da388c7759eeba3f01b8681b4a39d14f0e78d9ee9e742f769fd8022903c6cf8`
- `R/julia-bridge.R`: `00897301ef4db9f643ec1afa34773fc56dce177e09354f2089c32385009afd3e`
- `R/drmTMB.R`: `8dfd46bdb34ba21d7742e979fcf6ef6488a38d65fe27828f5d9fe3d3e1932f70`
- `DRM.jl/src/binomial_sd_regression.jl`: `67c80f0945907aea84711f18146259bdbf2b595c9ec851a867c18c5301931ceb`
- `DRM.jl/src/sparse_laplace_glmm.jl`: `97f19f36aea6eccf870004ca37e12e1ba031378d15f4c849e7620141be6f6bc8`
- `DRM.jl/test/test_binomial_phylo_sd_regression.jl`: `31178bedc806a28a5451ebde5428a45d66292cd1d86e820f67bd1ef146a3eca9`

## 6. Tests of the Tests

The native fixture exercises varying SDs, a constant-SD reduction, and prediction on held-out group rows. The bridge fixture checks link-scale and response-scale SD outputs, stored `sdpars`, and prediction with reordered new data. The current live test adds one same-data Julia/TMB comparison; it checks the fitted SD design and scale conversion but does not test a recovery grid.

## 7a. Issue Ledger

No issue was edited. This was a candidate-verification slice; the feature-level issue reconciliation remains open.

## 8. Consistency Audit

The formulas in the tested fixtures use the documented `sd(group, level = "phylogenetic") ~ z` syntax. No public docs, NEWS, roadmap, or package-navigation text changed because this turn verified existing candidate support rather than adding a route. The overall capability inventory and G0-G8 programme gates remain open.

## 9. What Did Not Go Smoothly

The native test's first invocation was skipped because its CRAN guard was active. Setting `NOT_CRAN=true` ran the intended fit tests. The first Julia bridge invocation also skipped the live case because no engine path was configured; the follow-up configured the paired worktree and ran one live comparison.

## 10. Known Residuals

This is one seeded native recovery fixture, the synthetic R-output assertions, one live Julia/TMB fixture, and a 21-assertion direct Julia test. It does not establish multi-seed recovery, calibrated uncertainty, broad Julia parity, or phylogenetic simulator correctness across non-unit tree heights.

## 11. Team Learning

Report CRAN-guard skips separately from actual test passes, and keep source-level output tests distinct from live Julia-engine evidence.

## 12. Cross-Product Coverage

The native Bernoulli phylogenetic slice has one tested fit and recovery fixture. The R bridge's synthetic output mapping passes, and one live Julia phylogenetic fit now matches the native fit at the test's tolerances. Other Bernoulli random-effect types, interval calibration, and the remaining family/effect/backend matrix are not closed by these checks.

This verification does NOT cover interval calibration, multi-seed recovery, other Bernoulli random-effect types, or the remaining response-family/effect/backend cells.

## Next Actions

Continue Bernoulli recovery and uncertainty calibration on the approved compute route. Audit the simulator's non-unit-tree-height scaling separately. Keep the full family/effect/backend matrix open.
