## 1. Goal
Rerun the existing same-data Bernoulli random-intercept SD test against the current native TMB source and the active Julia candidate branch, then retain exact source and test evidence.

## 2. Implemented
No package behavior changed. The existing `testthat` case passed with live Julia and source-loaded R/TMB code. It used the independent synthetic fixture `binomial_sd_fixture(groups = 300L, repeats = 12L, seed = 1701L)` and compared native and Julia coefficient recovery and group-level SD predictions. It also exercised Julia save/reload, profile-target handling, and three bootstrap refits.

## 3a. Decisions and Rejected Alternatives
- Kept this to one high-information point-parity fixture; it is not a recovery campaign or interval-coverage study.
- Loaded the R/TMB package from the current source worktree with `load_package = "source"`; the default installed-package route had loaded an older checkout.
- Set `JULIA_HOME` explicitly to the Juliaup binary directory because JuliaCall's login-shell lookup did not find `julia` on PATH.
- Assumption made without asking: the existing 36 assertions remain the suitable ordinary-intercept point-parity check; broader families and random-effect structures require separate evidence.

## 4. Files Touched
- Added `docs/dev-log/check-log.d/2026-10-24-live-julia-bernoulli-parity-rerun.md`.
- Added this after-task report.
- No source or test files changed.

## 5. Checks Run
The exact live command exited 0. `testthat` reported 36 assertions with no failures, skips, or warnings. The test ran one native TMB fit and one Julia bridge fit on identical data and preserved profile/bootstrap plumbing for the Julia SD coefficient. Julia ran with one thread and OpenBLAS with one thread.

Source state and hashes:

- R/TMB worktree: `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression`, branch `codex/general-sd-regression`, HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`.
- `R/drmTMB.R`: `ef8e2cb1f3fa0d1aabea6cb63462456c037be87f862cd98bb960394732f59d37`.
- `R/julia-bridge.R`: `8147d3d55f6ee31b04d9fd976ab88cbd97895a467920d94fef8310bce529c58a`.
- `R/random-effect-scale-formulas.R`: `7c1c005d3e36787f422ee7287498a7847608236473c0ab4627f9e146c8a358e6`.
- `src/drmTMB.cpp`: `601194d716c3816b787e4360f438a060bae3dd11292a90002d338da7bbb7a2a6`.
- `tests/testthat/test-julia-binomial-sd.R`: `bcc2970104bb4e30a3176f7a9ac1d95fb23d5b634607dcdf5e99c40ea360fc3c`.
- `tests/testthat/helper-binomial-sd-regression.R`: `acd2153d99bc46d4094cbf5d9a1abd05febd00cb9e9e2a3619d3325925df9018`.
- Julia worktree: `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia`, branch `codex/general-sd-regression`, HEAD `70dbf564eb670144c63c08f61ea099084d95add2`.
- `src/binomial.jl`: `3d97b695838c92f08cadfa08860f12bbfe32fdc26c0f6026a9db8b9dff5fd873`.
- `src/binomial_sd_regression.jl`: `1e4b7ecdf817672817e5e1dee1c8262c503f66a58a39f6c2282c1405c559f145`.
- `src/gaussian_core.jl`: `546147dea8f929dfa8a5fe23a7638237113b8b1eeaed1354a8313173f140c1fd`.
- `src/inference.jl`: `4b364e9845dda751fc740b286ebd6317d0175a6da5a2e28d5f98214af37b2add`.
- `test/test_binomial_sd_regression.jl`: `1bd69a36243af0ffcd0fb1e4645896449e43d1bf6ef48dcfb22a8579f0f782df`.

## 6. Tests of the Tests
The selected test requires both `engine = "tmb"` and `engine = "julia"` fits to converge on identical generated data, then compares recovered SD coefficients and named group predictions. It also serializes the Julia result and calls profile and bootstrap refit paths. Therefore a bridge-only mock or formula-builder-only test cannot pass in place of the live fit.

## 7a. Issue Ledger
- Found and corrected the test invocation's source selection: default `test_file()` loaded an installed stale package. The passing command explicitly requested `load_package = "source"`.
- Found and corrected the live Julia lookup: JuliaCall's login-shell search failed despite Juliaup being installed. Setting `JULIA_HOME` allowed JuliaCall to initialize the selected worktree.
- No model defect was demonstrated by the failed setup attempts.

## 8. Consistency Audit
The same-data fixture, native builder, TMB likelihood, Julia bridge, Julia family implementation, and public SD output test were checked at the hashes above. The evidence covers one ordinary Bernoulli logit intercept with predictor-dependent SD. The broader Julia Binomial test suite also passes 195/195 in the companion worktree, but this receipt does not promote that into cross-engine evidence for other route types.

## 9. What Did Not Go Smoothly
Two setup issues prevented the first live attempts from reaching the model: the default installed package was stale, and JuliaCall could not find Juliaup through its login-shell PATH. Explicit source loading and `JULIA_HOME` resolved both. The final run had no warnings.

## 10. Known Residuals
This is one ordinary random-intercept parity case. It does not establish parity for slopes, correlated or structured effects, non-logit links, other response families, or all outputs. Profile and three-refit bootstrap checks are workflow smoke tests, not uncertainty calibration. The full programme remains open.

## 11. Team Learning
For source-bound R/Julia bridge checks, specify both the R source-loading mode and Julia binary path explicitly. A passing test against an installed stale package is not evidence for the current worktree.

## 12. Cross-Product Coverage
This test covers native TMB and the paired Julia candidate for one ordinary Bernoulli random-intercept SD regression, including coefficient recovery and group-SD prediction. It does NOT cover structured effects, random slopes, non-logit links, other families, broad cross-engine parity, or interval calibration.
