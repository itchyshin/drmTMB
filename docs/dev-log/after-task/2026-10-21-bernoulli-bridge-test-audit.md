# After Task: Bernoulli Bridge Test Audit

## 1. Goal

Check the current Bernoulli/binomial SD test slice across native TMB and Julia bridge surfaces, and correct the stale unsupported-family error assertion found in that run.

## 2. Implemented

Updated one negative test to assert the current Julia bridge guidance for an unsupported Student structured combination. The implementation already reports that this combination should use `engine = "tmb"`; no model code changed. The focused animal-bridge file passes its 14 non-runtime checks.

## 3a. Decisions and Rejected Alternatives

Kept the current error text because it identifies the supported structured families and tells users to use TMB for other combinations. Updated the test expectation rather than restoring older generic wording.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-animal-sd-regression.R`
- `docs/dev-log/check-log.d/2026-10-21-bernoulli-bridge-test-audit.md`
- `docs/dev-log/after-task/2026-10-21-bernoulli-bridge-test-audit.md`

## 5. Checks Run

- Broad command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=1 DRM_JL_PATH='<paired DRM.jl worktree>' DRMODELS_JL_PATH='<paired DRM.jl worktree>' DRMTMB_JULIA_TESTS=true NOT_CRAN=true Rscript -e 'devtools::test(filter = "binomial.*sd", reporter = "summary", stop_on_failure = TRUE)'`. It exited 1 at testthat’s limit of 10 failures. Nine Julia bridge tests could not find `julia` through `bash -l -c 'which julia'`; one pure test expected the former generic error text. Native Bernoulli/binomial files progressed through animal, correlated, phylogenetic, relmat, integration, profile, simulation, and target-selector tests without a displayed native failure. The batch stopped before a complete total was reported.
- Julia retry with `/Users/z3437171/.juliaup/bin` on `PATH` found Julia 1.10.0, but JuliaCall setup remained silent beyond the three-minute estimate and emitted stale RCall pidfile warnings. I terminated only the R process I had started (PID 35552); the process exited with status 143 before tests began.
- Focused command: `NOT_CRAN=false DRMTMB_JULIA_TESTS=false OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^julia-binomial-animal-sd-regression$", reporter = "summary", stop_on_failure = TRUE)'`: 14 checks passed, 0 failed, 1 live-Julia bridge test skipped as configured.
- `git diff --check` on the test and report files: passed.

## 6. Tests of the Tests

The broad run reproduced the stale message expectation before it was changed. The focused file then passed its formula-admission, marshalling, and prediction checks. The live animal-slope Julia fit remains unverified by this focused run.

## 7a. Issue Ledger

No issue was changed. This slice updates a test expectation and records a local verification result; it changes no public model behavior.

## 8. Consistency Audit

The assertion now matches the current `drm_julia_structured_family_tag()` message and its recommended `engine = "tmb"` route. The candidate capability universe and all model code remain unchanged.

## 9. What Did Not Go Smoothly

The first broad run set `DRMTMB_JULIA_TESTS=true` but omitted Julia’s juliaup directory from `PATH`, so live bridge calls failed during setup. After adding the path, JuliaCall initialization exceeded the revised short-run estimate while another full-suite process was active in a separate candidate copy. I stopped my process and retained the failure details.

## 10. Known Residuals

The live Julia Bernoulli ordinary and animal bridge tests still need a successful run with JuliaCall initialization. The broad batch has no complete pass denominator because testthat stopped after ten failures. This slice does NOT validate interval coverage or general Bernoulli support across every effect/provider combination.

## 11. Team Learning

Before setting `DRMTMB_JULIA_TESTS=true`, add the juliaup executable directory to `PATH` and confirm `bash -l -c 'command -v julia'` succeeds. Treat a focused test-file result with live Julia skipped as source-side evidence only.

## 12. Cross-Product Coverage

The focused result covers native/source-side formula, marshalling, and prediction assertions in the Julia animal-bridge test file. It does NOT cover a live Julia fit, general engine parity, other families or providers, calibrated uncertainty, or programme completion.
