# After Task: Correct Julia Gamma animal simulation covariance

## 1. Goal

Make marginal simulation use the same animal covariance convention as the fitted Julia Gamma intercept-and-slope SD model when supplied `A` has a non-unit diagonal.

## 2. Implemented

The Gamma animal simulator now converts the saved relationship matrix to the unit-diagonal correlation used by DRM.jl's fitter before drawing latent effects. The simulation fixture now generates and reconstructs its seeded draw using that same correlation. The inventory no longer presents the earlier raw-`A` oracle as valid fit/simulation evidence.

## 3. Mathematical Contract

For supplied positive-definite `A`, the Julia Gamma fitter uses `R = D_A^{-1} A D_A^{-1}`, where `D_A = diag(sqrt(diag(A)))`. Its group SD predictions multiply latent effects with covariance `R`. The simulator must draw `u ~ N(0, R)` and form coefficient effects using the fitted group SD predictions; drawing from raw `A` would apply `sqrt(diag(A))` again.

## 3a. Decisions and Rejected Alternatives

Kept the fitted Julia covariance convention and normalized the simulation input at the R bridge boundary. Changing the fitter to preserve raw `A` would alter existing model semantics and exceed this correction. The route remains limited to the already-admitted Gamma animal intercept-plus-slope model.

## 4. Files Touched

- `R/julia-simulate.R`: normalize `A` after validating the retained matrix.
- `tests/testthat/test-gamma-animal-q2-nonunit-kernel-simulation.R`: generate data and build the exact seeded oracle using the fitted correlation.
- `docs/dev-log/general-sd-regression/inventory.md`: replace the invalid raw-kernel claim with the corrected evidence boundary.
- `docs/dev-log/evidence/gamma-animal-kernel-simulation-correction-20261024/`: focused test output and source hashes.
- `docs/dev-log/check-log.md`: record the failure-before-fix and passing regression run.

## 5. Checks Run

- Before the source fix, the corrected non-unit-kernel test failed at the seeded response comparison, with actual values differing from the normalized-correlation oracle. This reproduced the fit/simulation inconsistency.
- `devtools::test(filter = "gamma-animal-q2", reporter = "summary", stop_on_failure = TRUE)`: passed; three live Julia bridge tests ran, including the combined-target cross-engine fit, non-unit-kernel fit parity, and corrected marginal simulator.
- `Rscript` parsed the simulator and corrected test successfully.
- `git diff --check` passed for the tracked source and inventory changes.
- Stale-claim search over the current inventory, known limitations, and simulator source found no remaining claim that this Gamma simulator draws from raw `A`.
- Open issue search for "Gamma animal non-unit kernel simulation fit simulator" found no matching issue; no issue action was needed.

## 6. Tests of the Tests

The revised oracle failed against the old simulator before the fix and passed after the source changed. It reconstructs the response draw from an independently computed normalized covariance and the model's public SD predictions, then checks repeatability at the same seed. The earlier raw-`A` test and its report are retained as historical records; this report and the current inventory supersede their covariance interpretation.

## 8. Consistency Audit

The Julia source maps supplied animal `A` to a unit-diagonal correlation in `_general_cov_setup`; the Gamma animal fitter passes that precision into the fitted model. The simulator now applies the same normalization before generating random effects. The current combined-target non-unit fit-parity test and the simulation test agree with that interpretation. Public formula grammar and package navigation did not change. No broader family/effect support or uncertainty calibration is claimed.

## 7a. Issue Ledger

The open issue search returned no match. No issue was opened, commented on, or closed.

## 9. What Did Not Go Smoothly

The first seven-assertion simulation test used raw `A` both in the simulator and in its oracle. It passed while missing the mismatch with the fitted covariance. The independent source trace and a normalized-correlation oracle exposed the error.

## 11. Team Learning

For a structured simulator test, derive the random-effect draw from the covariance actually used by the fitted likelihood, then reconstruct the response independently. Matching a simulator to an oracle that copies its covariance choice is not enough.

## 10. Known Residuals

This correction covers only the Julia Gamma animal intercept-plus-numeric-slope SD route. Other structured Julia simulators, native TMB simulation parity, other families, bootstrap/profile workflows, and interval calibration remain outside this check. This does not close a programme gate.

## 12. Cross-Product Coverage

The correction changes one marginal simulation route in the R-to-Julia bridge. It does not add native TMB parity or alter the Julia fitter. No programme gate is closed.

This slice covers Julia Gamma animal q2 marginal simulation with supplied `A`. It does NOT cover other response families, providers, endpoints, engines, or prediction, bootstrap, profile, and uncertainty-calibration workflows.

## Prose Assessment

Style: 2/10, medium confidence because this is a short technical record with directly checkable claims. Genre and coverage: internal engineering after-task report, read in full. Evidence and repair: line 9 names the exact covariance transformation and its purpose; no change needed. Gates: science pass for the stated fitted covariance, facts pass against the source and focused test output, references not applicable because the report cites local evidence only. Provenance: Codex self-review, draft v1, 2026-10-24; the source code, test and console output were seen.

## Next Actions

Continue the family/effect/backend inventory and audit other structured simulators against their fitted covariance transformations. Keep interval coverage explicitly deferred until the implementation breadth work is complete.
