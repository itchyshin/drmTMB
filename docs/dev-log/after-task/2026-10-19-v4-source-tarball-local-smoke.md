# After Task: v4 Bernoulli Source-Tarball Local Smoke

## 1. Goal

Check whether the exact v4 `drmTMB_0.7.1.tar.gz` package archive installs into an isolated library and can fit one independent synthetic Bernoulli model with predictor-dependent random-intercept SD.

## 2. Implemented

Installed the v4 package archive into a fresh temporary library on macOS and fitted `y ~ x + (1 | id)` with `sd(id) ~ w`. The fit converged, had a positive-definite Hessian, passed an independent scalar-cluster Laplace objective comparison, and returned a finite 95% profile interval. This remains one installation and execution smoke check, not parameter-recovery or calibration evidence.

## 3a. Decisions and Rejected Alternatives

No product-model or calibration design changed. The local v4 tarball install and one fit were chosen as a bounded source/build smoke check while Totoro is occupied. Treating the prior v4 3,000-fit results as calibrated evidence was rejected because their receipt records a v2 DLL.

## 4. Files Touched

The synthetic data used group-level predictor values `w_i`, random intercepts with standard deviation `exp(-0.2 + 0.5 w_i)`, and the fitted formula `bf(y ~ x + (1 | id), sd(id) ~ w)`. The single fitted SD slope was `0.8136958`; its 95% profile interval was `[0.1387127, 1.943111]`. The independent Laplace-objective discrepancy was `1.19e-08` (predeclared smoke tolerance `1e-06`), the maximum absolute gradient was `8.93e-12`, and the log-SD clamp status was `ok`. One simulated dataset does not establish recovery or interval calibration.

## Files Changed

- `docs/dev-log/general-sd-regression/evidence/calibration-20261019/v4-source-tarball-local-smoke/` retains the smoke script, output, install log, command, and hash-bound receipt.
- `tests/testthat/helper-binomial-sd-regression.R` now rejects oracle inputs without binomial failure counts; `tests/testthat/test-binomial-sd-oracle-guard.R` retains the regression test.
- `docs/dev-log/check-log.md` records this validation result.
- This after-task report records the scope and remaining limits.

## 5. Checks Run

- The exact package tarball SHA-256 is `80e3a0314865777bf5343d56b072999f40b7daad07f794bc5347fa7cff8f0af7`; its embedded `src/drmTMB.cpp` hash is `1d172f604473d96a611a339a56c691a572b1acdaf508cf93103fc20ed61a0bb1`, matching the v4 source bundle.
- `R CMD INSTALL --preclean --no-multiarch` completed with `* DONE (drmTMB)` under R 4.6.0, Apple clang 21, on `aarch64-apple-darwin23`. The installation log and installed package artifact hashes are retained with the receipt.
- The saved `smoke.R` ran against the isolated package path and exited successfully: version `0.7.1`, optimizer convergence `0`, positive-definite Hessian, maximum absolute gradient `8.93e-12`, clamp status `ok`, independent scalar-cluster Laplace discrepancy `-1.19e-08` within `1e-06`, and finite 95% profile interval `[0.1387127, 1.943111]`. It loaded the DLL from the same isolated package directory. The run log and receipt bind the script and output hashes.
- `R_PROFILE_USER=/dev/null Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-binomial-sd-oracle-guard.R")'` passed 1/1 assertion. The log is retained beside the smoke output.
- The broader `test-binomial-sd-integration.R` run was interrupted after 21 assertions passed while fitting its independent-random-slope recovery case; it is not recorded as a suite pass. A first broad `devtools::test()` filter also selected beta-binomial contexts and was interrupted. These runs do not change the focused smoke or oracle-guard result.
- The first shell wrapper returned a nonzero status after installation because zsh reserves the variable name `status`. Direct inspection of the install log and a successful package load and fit confirmed that installation itself completed.

## 6. Tests of the Tests

The smoke run checks package loading, DLL resolution, model fitting, optimizer convergence, Hessian status, gradient, clamp status, an independent scalar-cluster Laplace objective, and profile-interval construction. The first enhanced run correctly failed its oracle assertion because the smoke data passed to the helper omitted the required `failure` column; this made the helper silently use zero trials and return an invalid near-zero objective. I added the binary failure counts (`1 - y`) to the smoke data and reran the exact v4 package successfully. A focused regression test first failed because the helper accepted missing failures, then passed after the helper gained an explicit input check. This is a test-harness guard, not a product-model change. No negative control or repeated-seed recovery/calibration test was added here.

## 7a. Issue Ledger

No issue was edited in this validation-only slice. The feature-level closeout still requires an overlapping-issue review.

## 8. Consistency Audit

The source hash inside the package tarball matches the v4 source bundle, and the fit loaded the DLL produced by that local installation. No model code or public support claim changed. The earlier Totoro v4 3,000-fit result still points to a v2 installed DLL and remains exploratory; this local result does not repair that provenance chain. No status-inventory or stale-wording scan was needed for this evidence-only check.

## 9. What Did Not Go Smoothly

The shell wrapper attempted to assign zsh's read-only `status` variable after `R CMD INSTALL`, which obscured the install command's actual success. The command log, isolated library, and fitted smoke result resolved that ambiguity. The first enhanced oracle check then exposed a missing `failure` column in the smoke fixture; inspection showed the helper's `y + failure` trial count was empty. Supplying the correct Bernoulli failure count produced a discrepancy of `-1.19e-08`. The compiler also reported existing unused-variable warnings in `src/drmTMB.cpp`; the build completed without error.

The exact integration test file exceeded the one-minute estimate and was stopped during its independent-random-slope fit after 21 assertions had passed. It remains unverified in this run; no worker process was left running.

## 10. Known Residuals

This check ran only on macOS. It does not establish Totoro source-to-binary provenance, Bernoulli coefficient recovery, interval coverage, false-positive control, Julia parity, or the wider supported-family/type matrix. The Julia phylogenetic simulator's raw-versus-normalized kernel scaling mismatch remains open.

## 11. Team Learning

Keep build output and model output bound to the exact source/package archive, installed library path, and DLL hash. A registry that records a source tree and a DLL path without a build/install receipt cannot establish that the DLL came from that source.

## 12. Cross-Product Coverage

This local check does NOT cover Totoro source-to-binary provenance, Bernoulli recovery, interval calibration, the Julia engine, any structured or correlated random-effect type, or the remaining response families. Those cells remain in the active general-SD goal.

The general-SD unlazy ledger remains open, including the native Bernoulli, calibration, ordinary-target, and Poisson gates; the after-task acceptance check therefore does not pass for the overall goal.

## Next Actions

After the active DRM.jl job releases the shared Totoro slot, install this exact package archive into a fresh isolated Totoro library, retain its build/install and runtime hashes, and run a source-bound smoke check. Reconcile the stage-two adapter's archive pin and first-look seal before considering another calibration campaign. Fix and test the Julia phylogenetic simulation covariance scaling in its owned lane.
