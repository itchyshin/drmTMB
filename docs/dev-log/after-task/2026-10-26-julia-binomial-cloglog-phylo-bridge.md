# After Task: Cloglog phylogenetic Bernoulli SD bridge

## 1. Goal

Complete the candidate R-to-Julia bridge admission for complementary log-log Bernoulli phylogenetic random-intercept models with predictor-dependent random-effect SDs, then verify it against native TMB on synthetic data.

## 2. Implemented

The development R bridge now admits the cloglog phylogenetic SD route alongside the existing probit route. It retains the family guard for unsupported links. A seeded live bridge fixture checks fits in TMB and Julia, SD coefficients, likelihoods, tip-level SD predictions, and the raw phylogenetic covariance scale.

## 3a. Decisions and Rejected Alternatives

- Preserve the supplied raw phylogenetic covariance scale, consistent with the programme contract.
- Keep unsupported links such as cauchit outside this route.
- Coverage calibration remains deferred. This slice provides focused fit and output checks only.
- These worktrees are development candidates. Release and main-branch status remain separate states.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-binomial-phylo-sd.R`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-cloglog-phylo-bridge-20261026/live-bridge-test.log`
- `docs/dev-log/general-sd-regression/inventory.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/after-task/2026-10-26-julia-binomial-cloglog-phylo-bridge.md`
- `docs/dev-log/check-log.d/2026-10-26-julia-binomial-cloglog-phylo-bridge.md`

## 5. Checks Run

Direct Julia test on the paired DRM.jl candidate, Julia 1.10.0:

```sh
JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia +1.10 --project=. test/test_binomial_cloglog_phylo_sd_regression.jl
```

Result: 29/29 checks passed, covering the cloglog phylogenetic SD fit, a mixed phylogenetic plus IID dense Laplace oracle, and probit/cloglog mixed-effect checks.

The R bridge test first failed as expected before the admission change, then the static route checks passed with live tests skipped, and finally the complete live bridge filter passed:

```sh
JULIA_HOME='/Users/z3437171/.juliaup/bin' \
DRMTMB_JULIA_TESTS=true \
DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null \
/usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-phylo-sd")'
```

Final result: 71 passed, 0 failed, 0 testthat warnings, 0 skipped; three live Julia tests ran in 119.0 seconds. The probit fixture emitted a near-singular Hessian warning for two coordinates (`rcond = 4.6681524208092426e-11`), so Wald standard errors for those coordinates remain untrustworthy.

The final bridge log SHA-256 is `18e85e9980e24230f6561c954b63c64b3989470b4766093cefcac4b38124027d`. Source hashes: `R/julia-bridge.R` `5966d1170c12e73bed99baba5fa4153ede4a98a29d1fbde4aafca032c552b145`; `tests/testthat/test-julia-binomial-phylo-sd.R` `bb6c0be230a2f64489f1d5227c07d7cb25b8e549ccfeaa19978448d7a2acf6e4`. Candidate HEADs remain drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1` and DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`; both worktrees are dirty.

## 6. Tests of the Tests

The red run showed that the cloglog phylogenetic route was refused before the bridge change. The final static checks admit probit and cloglog, reject cauchit at the family guard, and verify the refusal guidance. Live tests compare same-data fits and named predictions across the two engines. The direct Julia test includes a dense Laplace oracle. These checks are bounded to the tested synthetic routes.

## 7a. Issue Ledger

No issue was opened or changed for this focused bridge slice.

## 8. Consistency Audit

The candidate SD inventory now records the probit and cloglog bridge evidence and its limits. Public documentation remains with the separate documentation-audit lane. Cross-repository parity tracking remains with the parity lane. This slice changed no files in either lane's owned scope.

## 9. What Did Not Go Smoothly

The first negative test expected a route-refusal helper to report an unsupported family, but that helper correctly reports a formula-route mismatch. I changed the assertion to test the route predicate directly and the family parser separately. The corrected static checks passed. A final live rerun was made after the correction so the exact saved test source is covered by the 71-check result.

## 10. Known Residuals

- The probit fit in the combined filter has two nearly singular Hessian coordinates; Wald standard errors for those coordinates are not trustworthy.
- No repeated-sample recovery, interval coverage calibration, or general uncertainty claim is established.
- This is one synthetic cloglog phylogenetic random-intercept SD-regression route. Other providers, random-effect shapes, blocks, endpoints, families, and bivariate models remain open.
- A broader `git diff --check` found an unrelated pre-existing extra blank line at end-of-file in `tests/testthat/test-binomial-sd-integration.R`. That file was already dirty and was not changed in this slice.
- No full package suite, release, merge, or public documentation build was performed.

## 11. Team Learning

The SD modelling lane owns implementation and focused checks; the documentation audit and Julia parity work remain separate. Their owners were informed of the candidate route and test result. Do not infer public release or programme completion from a passing bridge filter.

Memory receipt: `route.py` found no `LOAD-FIRST` manifest for the repository. I used the checked-in Graft notes for the bridge and the current SD lane checkpoint. Golden Set: not run; this focused bridge verification did not target a registered repeated-mistake class.

## 12. Cross-Product Coverage

Covers: candidate R bridge, native TMB and Julia for one univariate Bernoulli/cloglog phylogenetic random-intercept model with a fixed-predictor SD regression; selected coefficient, likelihood, prediction, and direct-oracle checks.

Does NOT cover: calibrated uncertainty or interval coverage; other structured providers or random-effect types; other distributional endpoints; bivariate models; all-family parity; full package checks; merge or release readiness.
