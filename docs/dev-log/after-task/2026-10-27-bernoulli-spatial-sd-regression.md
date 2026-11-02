## 1. Goal

Add a bounded Binomial coordinate-spatial random-intercept SD route in native R/TMB and direct Julia, with fitting, prediction, and marginal simulation checks.

## 2. Implemented

The native Binomial builder now recognizes `sd_spatial(group)` and routes one coordinate-spatial intercept through the existing structured covariance and SD-design machinery. Native marginal simulation now admits a q1 Binomial spatial scale and uses the existing structured draw path.

The Julia Binomial structured-SD fitter now accepts one spatial intercept and builds its covariance from `coords`. The direct Julia marginal simulator accepts that provider and reuses the coordinate covariance. Tests cover logit, probit, and cloglog fits, SD predictions, and seeded marginal draws.

The coordinate kernels are engine-specific: native R/TMB uses its existing median-positive-distance range and 1e-6 jitter; Julia uses its existing mean pairwise-distance range and 1e-8 jitter. This is support in both direct engines, not same-data parity.

## 3a. Decisions and Rejected Alternatives

- Reused each engine's existing spatial covariance convention; no kernel normalization or range change was introduced.
- Kept the scope to one q1 coordinate-spatial intercept. Spatial slopes, mesh/SPDE providers, multiple structured fields, and bridge admission remain outside this slice.
- Assumptions made without asking: “spatial” means the existing coordinate-based route in each engine. If the intended contract requires identical covariance matrices across engines, a separate kernel-contract change is needed before a parity claim.

## 4. Files Touched

The following paths were touched by this slice; several source files also contain pre-existing changes from other SD work.

- `R/drmTMB.R`
- `R/methods.R`
- `tests/testthat/test-binomial-spatial-sd-regression.R`
- `src/binomial_sd_regression.jl` in the paired Julia worktree
- `src/inference.jl` in the paired Julia worktree
- `test/test_binomial_spatial_sd_regression.jl` in the paired Julia worktree
- `docs/dev-log/evidence/bernoulli-spatial-sd-20261027/native-test.log`
- `docs/dev-log/evidence/bernoulli-spatial-sd-20261027/julia-test.log`
- `docs/dev-log/evidence/bernoulli-spatial-sd-20261027/source-hashes.txt`
- `docs/dev-log/after-task/2026-10-27-bernoulli-spatial-sd-regression.md`
- `docs/dev-log/after-task/2026-10-27-bernoulli-spatial-sd-regression.assessment.md`

## 5. Checks Run

- `~/shinichi-brain/tools/lane_preflight.sh "$PWD" --file R/drmTMB.R`: completed; the tool reported no missing work on that path.
- `~/shinichi-brain/tools/lane_preflight.sh "$PWD" --file src/binomial_sd_regression.jl`: completed; no missing work was reported for that path.
- `~/shinichi-brain/tools/lane_preflight.sh "$PWD" --file src/inference.jl`: completed; no missing work was reported for that path.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^binomial-spatial-sd-regression$")'`: pass, 21/21, 5.5 seconds.
- Totoro, Julia 1.10.10, `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia --project -e 'include("test_binomial_spatial_sd_regression.jl")'`: pass, 21/21, 16.6 seconds.
- Local and Totoro SHA-256 values match for the Julia implementation and test files; see `source-hashes.txt`.
- The after-task structure check passed. Its 13 acceptance ledgers were not runnable because the gate checker or Node was unavailable; ledger state is unknown.
- Scoped `git diff --check` passed for the touched implementation, test, and report files. The whole-worktree check reports a trailing blank line at `tests/testthat/test-binomial-sd-integration.R:225`; that unrelated file was left unchanged.
- No full package test, documentation build, or interval-coverage campaign was run.

## 6. Tests of the Tests

The native test first failed at the unsupported Binomial SD-parameter gate. After enabling the route, it reached the fit and exposed the unsupported marginal-simulation gate. The final test covers logit, probit, and cloglog fits, SD-slope direction and a broad recovery bound, group-level SD predictions, and Bernoulli marginal draws.

The initial Julia fixture estimated an implausibly large SD slope with only 24 groups whose predictor alternated in spatial order. The fixture now randomizes the group-level predictor and uses 48 groups. Logit, probit, and cloglog runs all pass the fit, output, and independent seeded-draw checks. These are focused recovery checks, not calibration evidence.

## 7a. Issue Ledger

The open-issue search for “binomial spatial SD” found no specific matching implementation issue. No issue was created, edited, or closed. The broader open simulation-framework issue #59 was not changed.

## 8. Consistency Audit

The code uses the intended log-SD predictor, `log(tau_g) = W_g alpha`, with the existing spatial covariance multiplied by group-specific SDs. The R formula is `sd(group, level = "spatial") ~ predictors`; Julia uses `sd(group, spatial) ~ predictors`.

The task-specific search found stale inventory wording: `docs/design/01-formula-grammar.md` still lists Binomial structured effects as planned, and the roadmap still names only the animal direct-SD exception. I sent the exact test evidence and kernel caveat to the documentation-audit lane. I did not edit its owned documentation surfaces. The parity lane was also notified; no R-to-Julia spatial bridge or parity is claimed.

The Julia fit test initially failed to run locally because Julia is not installed on this Mac. The focused run was copied to a Totoro scratch project; its source hashes matched the candidate, and that scratch folder was moved to `/tmp` after use. A transient mistaken `closeout.py` call generated the report template under the brain repository because that script fixes its root to its own location; I moved that newly created template into this project before editing it.

## 9. What Did Not Go Smoothly

The first Julia fixture was too weak and spatially ordered, producing a boundary-scale fit despite a convergence flag. Increasing the number of groups and randomizing the predictor fixed the fixture; no tolerance was widened to accept the failed result. The first remote command also lacked Julia on the non-login PATH; the documented absolute Julia 1.10.10 path worked. The whole-worktree whitespace check also found an unrelated trailing blank line, which remains with its existing owner.

## 10. Known Residuals

- Documentation remains out of sync pending the documentation lane’s update.
- The native and Julia coordinate kernels use different default range and jitter rules; same-data cross-engine parity is unverified.
- R-to-Julia bridge support is not implemented or tested here.
- Only q1 coordinate-spatial intercepts are covered. Spatial slopes, mesh/SPDE effects, multiple structured fields, save/reload, profiling, bootstrap refits, and broader output workflows remain unverified.
- No interval-coverage or calibration claim is made.
- The overall predictor-dependent random-effect SD programme remains active.

## 11. Team Learning

Memory receipt: `route.py` returned no LOAD-FIRST manifest for this worktree. I queried `MEMORY.md` and found no directly applicable Bernoulli-spatial SD decision. The repository `after-task-audit` skill and this project’s lane instructions shaped the scoped path checks and negative-space report.

Golden Set: not checked; this slice did not trigger a known-mistake class requiring that regression suite.

The Totoro test was run from a disposable copy of the paired Julia source, with source hashes retained beside the test log. This provides a practical short-run pattern when the local Mac lacks Julia.

## 12. Cross-Product Coverage

Covers: Binomial/Bernoulli q1 coordinate-spatial random intercepts in native R/TMB and direct Julia; logit, probit, and cloglog; SD prediction and marginal simulation; focused recovery checks.

Does NOT cover: R-to-Julia bridge admission or parity; equality of the two engines’ coordinate kernels; spatial slopes or mesh/SPDE fields; additional simultaneous structured effects; save/reload, profiles, bootstrap refits, interval calibration, or any other response family’s spatial SD route.
