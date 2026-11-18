# After Task: Julia Binomial relmat SD bridge under probit and cloglog

## 1. Goal

Add focused cross-engine recovery and output evidence for the existing Binomial q1 relmat SD route under probit and complementary log-log.

## 2. Implemented

Added a fixed-seed live bridge test for one relmat intercept with a matching group-level SD formula under probit and cloglog. Each link fits the same generated data in native TMB and Julia, checks recovery and likelihood agreement, and compares named group SD predictions. Updated the family table, formula guide, vignette, and limitations note to describe this route in the development candidate.

## 3a. Decisions and Rejected Alternatives

The TMB and Julia builders already implemented the route, so this slice adds evidence and corrects documentation without widening the model interface. It keeps each link in its own synthetic fixture and does not mix the route with animal, phylogenetic, or other structured terms.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-relmat-nonlogit-sd-bridge.R`
- `docs/design/01-formula-grammar.md`, `docs/dev-log/known-limitations.md`, and `vignettes/julia-engine.Rmd`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and its generated summary
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-relmat-nonlogit-sd-bridge-live-20261029/`
- The check log, detail shard, lane checkpoint, and this report

## 5. Checks Run

The live focused test passed on macOS with Julia 1.10.0, covering probit and cloglog in one live bridge test with 22 passing expectations. For each link it checks positive, non-negligible SD-slope recovery; same-data TMB/Julia coefficient and log-likelihood agreement; and group-SD prediction agreement with both TMB and the generating values. `pkgdown::check_pkgdown()` found no problems and emitted existing Pandoc `--mathml` deprecation warnings. Evidence reconciliation passed with 20,350 candidate rows, 199 linked, 20,151 unlinked, and 222 evidence records; the four new rows remain unreviewed.

## 6. Tests of the Tests

The two links use separate fixed seeds and the same model design: 64 groups, 24 observations per group, named AR(1) covariance, and a normal group-level SD predictor. The live test fits both engines to the same responses for each link and aligns predictions by group name.

## 7a. Issue Ledger

No issue was created or changed. The new test covers the Julia development bridge's non-logit q1 relmat intercept route.

## 8. Consistency Audit

The family table and vignette describe probit and cloglog support only for one supplied-relmat q1 intercept with a matching SD formula in the paired development candidate. They do not imply support for relmat slopes, multiple structured terms, other providers, or the current shared/released DRM.jl build. Evidence is point-fit and recovery evidence; no interval calibration or coverage is claimed.

## 9. What Did Not Go Smoothly

The first test run stopped because this testthat version rejects `info` in `expect_gt()`. I removed the unsupported argument and reran the live test successfully. I saved the passing rerun console output.

## 10. Known Residuals

This is one synthetic fixture per link. The bridge route remains a development-candidate feature; support in the shared/released DRM.jl source and calibrated intervals remain open. Broader Bernoulli/provider parity is still incomplete.

## 11. Team Learning

Before changing bridge code, verify whether both the engine fitter and the R bridge already admit the family/link/target combination. When the route exists, a small same-data test can close an evidence gap without changing the interface.

Memory receipt: `MEMORY.md:2-5` and `MEMORY.md:55-56`; I kept candidate parity and coverage claims separate. Golden Set: not run; no matching registered case applied. Prose assessment: `docs/dev-log/after-task/2026-10-29-julia-binomial-relmat-nonlogit-sd-bridge.assessment.json`.

## 12. Cross-Product Coverage

Covers one native R/TMB and paired R-to-Julia Binomial relmat q1 intercept SD model under probit and cloglog, with fixed-seed recovery and point-output comparisons.

Does not cover interval calibration, coverage, structured slopes, other providers, the shared/released DRM.jl build, or full programme completion.
