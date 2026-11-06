## 1. Goal

Enable the R-to-Julia bridge for Binomial related-matrix random slopes with predictor-dependent SDs and verify the route for logit, probit, and cloglog links.

## 2. Implemented

The R bridge now admits a single `relmat(0 + x | id, K = K)` Binomial mean term paired with `sd(id, level = "relmat") ~ z`. The matching gate requires a slope-only term and rejects intercept-plus-slope and extra independent random effects. DRM.jl bridge label reconstruction now enables its existing related-matrix slope parser only when a Binomial fit has a related-matrix SD target.

Added a fit-free marshalling test and an opt-in live cross-engine test. On JuliaCall 1.10.0, the live test passed 31 assertions across three links. It checks optimizer convergence, SD coefficient recovery, R/TMB/Julia coefficient and log-likelihood agreement, group SD predictions, and seeded simulation reproducibility within Julia.

## 3a. Decisions and Rejected Alternatives

Kept the route restricted to one related-matrix slope-only member. Broader combinations are not inferred from the parser's general capability. Did not compare Julia's seeded simulation output with an R-generated random sequence because the engines use different random-number generators. The initial live test showed the mismatch; the rerun checks same-engine reproducibility and binary response validity instead.

Assumption: for this point-parity slice, optimizer convergence and cross-engine likelihood agreement are the numerical gates. The test does not require a positive-definite Hessian or advertise Wald inference; if that is not the intended threshold, the inference gate needs separate review.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-binomial-relmat-slope-sd-bridge.R`
- Paired DRM.jl worktree: `src/bridge.jl`
- This after-task report

The source trees contain unrelated concurrent edits. They were preserved.

## 5. Checks Run

- `PATH="$HOME/.juliaup/bin:$PATH" DRM_JL_PATH="$PWD/../general-sd-julia" OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter="julia-binomial-relmat-slope-sd-bridge", reporter="summary")'`: passed 31 assertions, including one live bridge block for logit, probit, and cloglog, on JuliaCall 1.10.0.
- The same focused filter without Julia on PATH passed the 7 marshalling assertions and skipped its live block as expected.
- A first live run completed all fitting and cross-engine checks but failed the invalid cross-language RNG equality assertion. Replacing that assertion with Julia same-seed reproducibility produced the passing run above.
- `git diff --check` passed on the test file and R bridge diff. `git diff --check` passed on the paired Julia bridge diff.

## 6. Tests of the Tests

The fit-free test rejects intercept-plus-slope and extra independent-effect routes. The live test runs the same synthetic data through native TMB and Julia for three links and checks coefficient recovery and point agreement. Its first failure demonstrated that the original R-versus-Julia random draw equality was not a valid cross-engine oracle.

## 7a. Issue Ledger

Fixed: the R route and payload previously rejected Binomial related-matrix slope-only SD models; the Julia bridge label renderer lacked the existing parser opt-in.

Deferred: broader structured Binomial combinations, interval calibration, and capability-guide reconciliation remain in the parent programme.

## 8. Consistency Audit

Checked the exact R admission gate, payload serialization, Julia bridge formula-label path, and existing direct/native related-matrix slope tests. The scope remains limited to Binomial `relmat` slope-only models. This change does not alter the supplied covariance matrix or its scaling.

## 9. What Did Not Go Smoothly

The local shell did not initially expose Julia on PATH, and a Totoro R-to-Julia run is unsuitable because its R/Julia embedding has a recorded crash. After adding the installed local Julia 1.10 path, the first live run exposed an invalid expectation that R and Julia random-number generators produce identical draws from the same integer seed. The test was corrected to check reproducibility within Julia.

## 10. Known Residuals

This is point-recovery and cross-engine evidence for one Bernoulli effect/provider shape. It does not establish interval coverage, Hessian-based uncertainty, other response families or random-effect types, or complete Julia parity. The after-task report is recorded; the shared check log and public capability guide still need integration with the active documentation/audit lane.

## 11. Team Learning

Memory receipt: `route.py` reported no LOAD-FIRST manifest for this worktree. The compute-routing guide was read before attempting the live fit; its Totoro warning ruled out running the R/Julia embedding there. This task did not scout a sister project or change a known-mistake guard.

Golden Set: not in scope for a bridge admission and test correction.

## 12. Cross-Product Coverage

Covers: R-to-Julia fitting and output checks for Binomial related-matrix slope-only SD regression with logit, probit, and cloglog links; native TMB is the point comparator.

Does NOT cover: interval calibration, Wald inference, other response families, other structured effects, multiple members or blocks, package-wide capability status, or broad engine parity.
