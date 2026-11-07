# After Task: Probit phylogenetic Bernoulli SD bridge

## 1. Goal

Verify that the candidate probit Bernoulli phylogenetic SD-regression route works through the live R-to-Julia bridge and agrees with native TMB on the same synthetic data.

## 2. Implemented

The bridge admission and fixture were already present in the SD candidate. This slice ran the complete focused bridge file with live Julia enabled and retained its output. All 61 expectations passed, including two live Julia fits. A test-only overlay also allowed the focused R-to-Julia profile and bootstrap endpoint checks to complete. This workflow smoke demonstrates endpoint execution under the overlay; it makes no coverage-calibration claim and did not change production source. Its log is `../general-sd-regression/evidence/julia-binomial-probit-phylo-workflows-20261026/bridge-backtracking-3000.log`. Separately, an isolated copy of the Julia candidate with the retry patch passed 55 direct assertions, recorded in `../general-sd-regression/evidence/julia-binomial-probit-phylo-workflows-20261026/profile-retry-isolated-probe-20261026.log`.

The probit fixture compares fitted SD coefficients, likelihoods, and predicted tip-level SDs between TMB and Julia. It also checks reordered-tip predictions and a finite profile interval for the Julia SD slope. This is one fixed-seed synthetic case.

## 3a. Decisions and Rejected Alternatives

- Keep the existing raw phylogenetic kernel scale. The test warns that the maximum tree height is 2.5 and reports SDs on that raw branch-length scale; it does not normalize the kernel.
- Do not describe the singular-Hessian result as reliable Wald uncertainty. The fit warns that two coordinates are near-singular and directs users to profile or bootstrap methods.
- Keep coverage calibration deferred, as directed by the project owner. The finite profile endpoints show route execution, not calibrated intervals.
- Assumption: use the active SD candidate worktrees as the test source. These are development candidates and are not the released package or current `main`.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/julia-binomial-probit-phylo-bridge-20261026/live-bridge-test.log` (new test output)
- `docs/dev-log/general-sd-regression/inventory.md` (updated candidate evidence and superseded pre-retry status)
- `docs/dev-log/after-task/2026-10-26-julia-binomial-probit-phylo-bridge.md` (this report)
- `docs/dev-log/check-log.d/2026-10-26-julia-binomial-probit-phylo-bridge.md` (focused check receipt)

No source or test code was edited during this verification slice. The bridge and test were already in the dirty SD candidate. Source hashes at verification are recorded below.

## 5. Checks Run

Successful command, from the `general-sd-regression` candidate:

```sh
JULIA_HOME='/Users/z3437171/.juliaup/bin' \
DRMTMB_JULIA_TESTS=true \
DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null \
/usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-phylo-sd")'
```

Result: 61 passed, 0 failed, 0 testthat warnings, 0 skipped; two live Julia tests ran. Runtime was 118.5 seconds on Julia 1.10.0. Julia emitted a numerical warning that the probit phylogenetic fit has two nearly singular Hessian coordinates (`rcond = 4.6681524208092426e-11`). The test suite still passes, but those coordinates do not have trustworthy Wald standard errors. Trailing padding from testthat’s progress display was trimmed from the saved console file.

The current Julia candidate's direct source-bound rerun also passed all 55 assertions: joint fit/oracle 27/27, phylogenetic intercept 23/23, and probit SD-slope profile endpoints 5/5. Julia still reports a non-positive-definite Hessian and withholds Wald SEs. This confirms profile workflow execution for this fixture, not calibrated uncertainty. Saved transcript: `../general-sd-regression/evidence/julia-binomial-probit-phylo-workflows-20261026/direct-phylo-sd-test-20261026-profile-retry-current.log`. `src/inference.jl` SHA-256: `fe7243ffd52c33e047ae4fd01d1fe9992d78a48e84955188e0e094b72a726621`; test SHA-256: `a94debee744dba611daa1c88ad64fa529af3b7a93753f8cc31dae8d326276e72`; log SHA-256: `ce1a1896b487a7e727a19d966dc639fbc4d9953d8070c1470cdf7c3c9dae99ba`.

The paired R-to-Julia bridge filter was rerun against that current Julia candidate and exited 0 with three live Julia tests. It repeated the warning that two probit Hessian coordinates are nearly singular; Wald SEs remain withheld. The log is `../general-sd-regression/evidence/julia-binomial-probit-phylo-bridge-20261026/live-bridge-profile-retry-current.log` (SHA-256 `fd55988d3aa3de25da540b51c74441c4ea81d3accd2412b75b2e66157d4b4886`). R bridge SHA-256: `896215ca04358b4b42c6d2c91f66c8ee8a5d882facd8b7237341ee1db65d5a95`; focused test SHA-256: `bb6c0be230a2f64489f1d5227c07d7cb25b8e549ccfeaa19978448d7a2acf6e4`.

Candidate source identifiers:

- drmTMB HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- DRM.jl HEAD: `70dbf564eb670144c63c08f61ea099084d95add2`
- `R/julia-bridge.R`: `d3240442ad139222bfe84e2cff055349b820d09f4d45071f62ab783de627c967`
- `tests/testthat/test-julia-binomial-phylo-sd.R`: `001996362052b626ce3f3b768ac400525a3c19ebe72bc853203934d6c334dec3`
- `DRM.jl/src/inference.jl`: `bc9592479f22a50a2c46efcb7bac09c120d1b0c64eda8254aa04a64026419c0d`
- Saved test log: `a756a0717cb280805265d5b2c1b57ea6e892c713817f50cc6635ee7ef3a4450a`

## 6. Tests of the Tests

The static bridge checks accept probit phylogenetic SD regression and reject the same structured route under complementary log-log. The live tests fit the admitted route through R for both engines and compare named coefficients, likelihoods, and fitted SD predictions; they also check tip reordering and a finite profile interval for the selected Julia SD slope. The earlier profile failure and its repair are retained in the linked report; the test was not weakened to accept a non-converged endpoint.

## 7a. Issue Ledger

An open-issue search for `repo:itchyshin/drmTMB binomial phylogenetic SD probit Julia bridge` returned no matching issue. No issue was opened or changed.

## 8. Consistency Audit

The candidate SD inventory was updated to replace the stale pre-retry status with the current focused receipts. I searched `NEWS.md`, `docs/design/18-random-effect-scale-models.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`, and `vignettes/julia-engine.Rmd` for `probit`, `phylogenetic`, and `non-logit`. This verification did not change public documentation; the separate documentation-audit lane retains those pages. The check-log records the exact search and result.

## 9. What Did Not Go Smoothly

The first two bridge attempts failed before model fitting because JuliaCall could not locate Julia: the login shell did not include Juliaup, and JuliaCall expects `JULIA_HOME` to be the containing directory rather than the executable path. Setting `JULIA_HOME` to `/Users/z3437171/.juliaup/bin` fixed setup. These attempts produced no fit results and are not included as successful evidence.

The closeout generator resolved a relative report path against the brain repository. I removed that generated stub and created the report at the absolute drmTMB candidate path.

## 10. Known Residuals

- The Hessian is nearly singular in two coordinates. Wald standard errors are not trustworthy for them.
- The run contains two live fits and one synthetic dataset. It does not establish repeated-sample recovery, interval coverage, or calibration.
- This receipt covers a probit phylogenetic intercept with a predictor-dependent SD slope only. Other providers, correlated blocks, crossed/nested layouts, other distributional parameters, other response families, and broad Julia/native parity remain open.
- No full package suite, public-doc build, release, or merge was performed.

## 11. Team Learning

Memory receipt: the repo routing tool found no `LOAD-FIRST` manifest for drmTMB. I used the repository Graft node for `R/julia-bridge.R`, the relevant lane checkpoint, and a targeted brain search. The lane lesson that a preflight is not a lease shaped the scoped claim; the claim was granted before evidence files were written. `graft` was not on this shell's PATH, so I read the checked-in graph node directly.

Golden Set: not run. This slice verified one existing bridge route and did not target a registered repeated-mistake class.

Useful process correction: when JuliaCall reports that Julia is missing on this Mac, set `JULIA_HOME` to the Juliaup bin directory, then verify the version from JuliaCall before interpreting a bridge failure as a model failure.

## 12. Cross-Product Coverage

Covers: candidate R bridge, native TMB, and Julia for one univariate Bernoulli/probit model with a phylogenetic random intercept and fixed-predictor SD regression; selected coefficient, likelihood, prediction, and profile workflow checks.

Does NOT cover: calibrated uncertainty or Wald inference for the flagged coordinates; cloglog phylogenetic models; other structured providers or random-effect shapes; bivariate models; other response families or distributional endpoints; full R/Julia package checks; release readiness.
