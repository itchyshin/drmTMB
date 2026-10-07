# Curie M2 recovery-smoke fixture receipt — 2026-10-06

## 1. Goal

Prepare a deterministic, shared R/Julia fixture and frozen manifest draft for the M2 fixed-effects CJS recovery smoke. This receipt covers fixture preparation only; it does not claim model recovery or interval calibration.

## 2. Implemented

Added `bench/cmr_m2/` in both product worktrees with one shared SplitMix64-v1 generator, literal history and keyed predictor CSVs, and `manifest-draft.json`. The fixture contains two fixed-effects cells, two seed-separated datasets per cell, 32 individuals per dataset, five occasions, irregular intervals, administrative endpoints, survey masks, and final-first histories. Each product worktree has byte-identical generator, manifest, and CSVs.

The survival cell estimates `beta_phi = (1.20, -0.45)` with `p` fixed at 0.60. The detection cell estimates `beta_p = (0.10, 0.65)` with `phi` fixed at 0.80. Both use logit links and the interval survival rule `logistic(X_phi beta_phi)^Delta`. The first capture is fixed and its emission is conditioned upon.

## 3a. Decisions and Rejected Alternatives

The fixture generator uses a specified SplitMix64-v1 stream and a fixed seed formula so it does not depend on R or Julia's default RNG implementation. The generated CSVs, not independently regenerated language-specific draws, are the shared fit inputs. The smoke manifest keeps the two component estimands separate and records the terminal constraint needed to identify each cell.

The M2 methods are visible in concurrent, uncommitted edits in both worktrees. This slice did not run a fit or call those methods because its validation boundary was limited to light parsing and fixture-integrity checks. Their implementation and execution remain unverified here.

## 4. Files Touched

New paths only: `bench/cmr_m2/generate_fixture.py`, `bench/cmr_m2/manifest-draft.json`, `bench/cmr_m2/fixtures/{histories,phi_predictors,p_predictors}.csv`, and this receipt at `docs/dev-log/cmr/curie-m2.md` in each product worktree. No production code or package tests were edited by this slice.

## 5. Checks Run

In each product worktree, ran `python3 bench/cmr_m2/generate_fixture.py` and `python3 -m json.tool bench/cmr_m2/manifest-draft.json`. The generator reported four datasets and 640 history rows. A light CSV integrity check verified 128 individuals, one earliest observed capture per history at the declared first-capture occasion, no captures after administrative end, and blank capture values exactly at masked occasions. The fixture generator, three CSVs, and manifest copies were compared by SHA-256; the data and generator hashes agree across products.

No package tests, Julia/R fits, or 500/2000-replicate campaign ran. No runtime estimate for a fit is therefore claimed. The manifest requires a measured per-fit estimate before the later 10-fit pilot; any projected run above three hours needs a pre-run test and approval.

## 6. Tests of the Tests

The CSV check reads only the frozen fixture and verifies capture layout, masking, and endpoints. The regeneration command provides a byte-level determinism check against the checked-in CSVs. These checks do not validate the public M2 generator, likelihood fit, coefficient recovery, or Wald/profile/bootstrap intervals.

## 7a. Issue Ledger

No public issue was opened. The manifest labels the smoke fixture as pending API execution and leaves qualification, coverage, and performance claims pending.

## 8. Consistency Audit

The R and Julia worktrees contain byte-identical shared fixture inputs. Formula labels, coefficient order, terminal constraints, truths, interval lengths, and unit labels are recorded together in the manifest. The seed registry separates the fixture smoke from future pilot, screen, and qualification streams. Failed, nonconverged, boundary, singular-Hessian, and errored attempts remain in the denominator rules; retries and replacement seeds are prohibited.

## 9. What Did Not Go Smoothly

The mandated `tools/lane_preflight.sh` and repository `LOAD-FIRST` manifest were absent from the supplied worktree. Graft queries provided no useful CJS-M2 source node; the available CJS M1 receipts and the supplied M2 contract were used as the technical anchors. The integrity check initially used an overstrict assertion that required only one capture over an entire history; it was corrected to test that the earliest observed capture matches the declared first-capture occasion. No fixture data changed because of that assertion correction.

## 10. Known Residuals

The literal datasets are tiny and serve deterministic pipeline smoke only. Two datasets per cell do not establish recovery, identifiability, interval availability, nominal coverage, boundary validity, speed, or R/Julia optimizer parity. The proposed future pilot, 500-replicate screen, and 2,000-replicate qualification are explicitly not authorized or run by this manifest. Calibration status remains pending.

## 11. Team Learning

A custom, explicitly specified PRNG plus literal shared inputs makes a cross-language smoke reproducible without relying on language-specific RNG details. Check masked emissions and absorbing death independently from coefficient fitting; a deterministic fixture proves only its recorded construction and integrity.

## 12. Cross-Product Coverage

This receipt covers deterministic fixture generation, shared-byte identity, manifest parsing, and basic history-layout checks in the Julia and R worktrees. It does not cover M2 method execution, prediction, conditional simulation through either product API, fixed-effect recovery, inference, coverage, campaign performance, package regression, or publication readiness.
