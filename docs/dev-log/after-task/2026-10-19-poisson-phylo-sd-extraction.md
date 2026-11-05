# Poisson phylogenetic SD coefficient extraction

## 1. Goal

Preserve fitted predictor-dependent phylogenetic SD coefficients in the public parameter split for Poisson models.

## 2. Implemented

`split_tmb_parameters()` now extracts the phylogenetic SD coefficient slice using the shared offset helper and restores each target's coefficient names. A deterministic unit test checks the target label, intercept, and slope.

## 3a. Decisions and Rejected Alternatives

The change reports the parameterization already fitted by the model. It does not rescale the existing covariance kernel or reinterpret its scale. The cross-engine prediction assertions were left for their active test owner because they compare Julia predictions to values calculated from native coefficients.

## 4. Files Touched

Implementation and regression test: `R/drmTMB.R` and `tests/testthat/test-poisson-sd-assembly.R`. Evidence records: this report, `docs/dev-log/check-log.md`, and `LOOP/lanes/general-sd-regression/checkpoint.md`. Other working-tree changes belong to concurrent programme work and are not attributed to this slice.

## 5. Checks Run

`Rscript -e 'devtools::test(filter = "poisson-sd-assembly", reporter = "summary")'` passed. Its Julia bridge step ran zero live engine tests, so this is R assembly and extraction evidence only. `git diff --check` passed on the tracked touched paths; the untracked report also passed a whitespace check. The report passed `slop_check.py` with zero findings. `check-after-task.R` passed the report-shape check, then exited 1 because the programme acceptance ledger still has unmet family, Julia, and calibration gates. The programme remains open.

## 6. Tests of the Tests

The test supplies a two-column SD design and a matching `beta_sd_mu` vector, then asserts both the returned target key and named coefficient values. It would fail if the phylogenetic coefficient slice were omitted or mislabelled.

## 7a. Issue Ledger

The earlier search of open GitHub issues found no issue specific to Poisson phylogenetic SD coefficient extraction. No issue was changed.

## 8. Consistency Audit

The extraction uses the same offset and coefficient-name metadata as the existing phylogenetic SD assembly. No formula grammar or likelihood parameterization changed. The project-wide capability inventory was not repeated for this output-only fix.

## 9. What Did Not Go Smoothly

The live cross-engine Poisson phylogenetic SD test previously exposed two Julia prediction/output expectations that use native-fit coefficients despite allowing small cross-engine coefficient differences. An earlier lease ledger named `codex:general-sd-scale-roundtrip`; the current lease listing no longer shows it. Per Shinichi's instruction to wait for owner handoff, I left the test file untouched.

## 10. Known Residuals

The result does not establish recovery, calibrated uncertainty, cross-engine parity, or complete Poisson phylogenetic SD workflow support. For a structured block with non-unit kernel diagonal, the returned SD regression is a multiplier; marginal SD also depends on the kernel diagonal. This fix leaves that convention unchanged.

## 11. Team Learning

Cross-engine coefficient tolerances and same-engine prediction checks need separate expected values. Small coefficient differences can produce small prediction differences even when each engine's own output is internally correct.

## 12. Cross-Product Coverage

This slice covers only R/TMB parameter extraction and its deterministic unit test. It does NOT cover the live Julia bridge, prediction, recovery, interval calibration, other response families, or other random-effect types.
