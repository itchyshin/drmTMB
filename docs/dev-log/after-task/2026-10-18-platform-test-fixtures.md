# Platform test fixtures

## 1. Goal

Repair the test assumptions exposed by the platform failures in #1521, preserving numerical tolerances and runtime behavior.

## 2. Implemented

The conditioning test grades only the Hessian rows it is designed to exercise. The q4 objective fixture now generates replicated signals for all four endpoints, and requires convergence and a positive-definite Hessian before its unchanged 1e-8 objective anchor. The count pilot prints its failure rows without relaxing the zero-failure requirement.

## 3a. Decisions and Rejected Alternatives

Do not increase the objective tolerance or skip an unhealthy q4 fit. Replace the unsupported optimum premise with a seeded generated fixture that actually converges. Preserve every existing error and displacement assertion. Carry only the test hunks from existing lanes, with provenance in the dedicated README.

## 4. Files Touched

Three tests: test-check-conditioning.R, test-objective-at.R and test-phase18-count-mu-random-effect-pilot.R. Dedicated evidence and this report. No R, C++, runner, checker or workflow source changes.

## 5. Checks Run

The original q4 fixture reported false convergence and a nonpositive Hessian. Its new convergence premise failed before replacement. The generated related-tip fixture converged with positive Hessian, maximum gradient 1.47e-9, and zero objective anchor difference. The full three-file targeted suite passed with no failures, one existing NaNs-produced warning and one existing non-PD platform skip. git diff --check and runtime source equality against base 476afc4 passed. Exact output is retained in the dedicated check log.

## 6. Tests of the Tests

The convergence assertion rejects the old fixture. Existing unknown-axis, unknown-label and correlation-parameterization refusal cases remain. The strict 1e-8 objective anchor and displaced rho12/phylogenetic-SD comparison remain unchanged. The pilot still fails on any recorded warning or failed fit.

## 7a. Issue Ledger

Addresses the conditioning and objective fixture premises from existing #1521. The unknown Windows pilot warning remains open pending the newly printed diagnostic. No duplicate issue is needed; the repair PR links #1521.

## 8. Consistency Audit

The README pairs the generated equations, covariance draws and fitted formulas term by term. The tree covariance normalization differs only by an absorbed scalar standard deviation, explicitly documented. Independent review found no blocking concern and identified two stale fixture comments; both are corrected. No public API, design, NEWS or pkgdown content changes are needed for these test-only repairs.

## 9. What Did Not Go Smoothly

The previous objective test called an unconverged near-degenerate fit its optimum. On this Mac, the conditioning fixture becomes non-PD and follows its existing skip; its separate rank-deficiency warning is expected on platforms where the Hessian is resolved. The targeted suite rebuilt the unchanged C++ backend in the isolated worktree.

## 10. Known Residuals

A changed test fixture does not prove the historical Windows objective drift had only one cause. Windows validation remains required. Printing the pilot warning is diagnostic, not a numerical fix. No fitting warning is silenced or reclassified.

## 11. Team Learning

Anchor tests must assert the numerical premise they rely on. A Hessian-specific test should not demand that unrelated diagnostics report no warnings. Failure tables must print their reasons on assertion failure.

## 12. Cross-Product Coverage

Covers existing native conditioning diagnostics, q4 phylogenetic REML objective mapping, and count pilot reporting. This does NOT cover every family, optimizer, platform, covariance-label mapping, interval calibration, real collaborator data or Julia engine execution.

## Prose review

Self-review, 18 October 2026, whole report and dedicated README, for package contributors. Perceived AI-like style 2/10, medium confidence: the source hashes and explicit negative space make the claims inspectable. No repair needed for those passages. Science gate: pass for the generated covariance construction, checked against formulas and independent review. Facts gate: pass within the retained probes and source diff; platform outcomes remain pending. Reference gate: pass for issue and commit identifiers checked against GitHub and all-ref history. This is editorial self-review, not independent runtime validation.
