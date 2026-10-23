# Platform test fixtures

## 1. Goal

Repair the test assumptions and root-caused interpolation warning exposed by the platform failures in #1521, preserving numerical tolerances and interval values.

## 2. Implemented

The conditioning test grades only the Hessian rows it is designed to exercise. The q4 objective fixture now generates replicated signals for all four endpoints, and requires convergence and a positive-definite Hessian before its unchanged 1e-8 objective anchor. The count pilot prints its failure rows without relaxing the zero-failure requirement. Its Windows diagnostic exposed implicit interpolation ties; the shared profile wrapper now names ties = mean explicitly, preserving TMB interval values without that warning.

## 3a. Decisions and Rejected Alternatives

Do not increase the objective tolerance or skip an unhealthy q4 fit. Replace the unsupported optimum premise with a seeded generated fixture that actually converges. Preserve every existing error and displacement assertion. Carry only the test hunks from existing lanes, with provenance in the dedicated README.

## 4. Files Touched

Three tests: test-check-conditioning.R, test-objective-at.R and test-phase18-count-mu-random-effect-pilot.R. Dedicated evidence and this report. Also R/profile.R, inst/COPYRIGHTS, NEWS.md, a pure profile-interpolation regression test and the genuinely refreshed source-bound parity receipt. No C++, runner, checker or workflow source changed.

## 5. Checks Run

The original q4 fixture reported false convergence and a nonpositive Hessian. Its new convergence premise failed before replacement. The generated related-tip fixture converged with positive Hessian, maximum gradient 1.47e-9, and zero objective anchor difference. The full three-file targeted suite passed with no failures, one existing NaNs-produced warning and one existing non-PD platform skip. git diff --check passed. Runtime source equality held for the initial test-only repair; the final runtime change is confined to R/profile.R as documented below. Exact output is retained in the dedicated check log.

## 6. Tests of the Tests

The convergence assertion rejects the old fixture. Existing unknown-axis, unknown-label and correlation-parameterization refusal cases remain. The strict 1e-8 objective anchor and displaced rho12/phylogenetic-SD comparison remain unchanged. The pilot still fails on any recorded warning or failed fit.

## 7a. Issue Ledger

Addresses the conditioning and objective fixture premises from existing #1521. The Windows pilot warning was identified as implicit interpolation ties and addressed in the shared profile wrapper. Final Windows validation of that fix remains pending. No duplicate issue is needed; the repair PR links #1521.

## 8. Consistency Audit

The README pairs the generated equations, covariance draws and fitted formulas term by term. The generated correlation equals the fitted Brownian covariance divided by tree height, explicitly documented. Independent review found no blocking concern and identified two stale fixture comments; both are corrected. NEWS records the profile warning fix; no public API or likelihood changed. The shared wrapper covers all three profile extraction callers. inst/COPYRIGHTS records the independently implemented TMB interval convention. No site navigation or reference signature changed.

## 9. What Did Not Go Smoothly

The previous objective test called an unconverged near-degenerate fit its optimum. On this Mac, the conditioning fixture becomes non-PD and follows its existing skip; its separate rank-deficiency warning is expected on platforms where the Hessian is resolved. The targeted suite rebuilt the unchanged C++ backend in the isolated worktree.

## 10. Known Residuals

A changed test fixture does not prove the historical Windows objective drift had only one cause. Final Windows validation remains required. The warning is now root-caused and its implicit tie handling made explicit; no warning handler silences production warnings. No fitting warning is reclassified.

## 11. Team Learning

Anchor tests must assert the numerical premise they rely on. A Hessian-specific test should not demand that unrelated diagnostics report no warnings. Failure tables must print their reasons on assertion failure.

## 12. Cross-Product Coverage

Covers existing native conditioning diagnostics, q4 phylogenetic REML objective mapping, and count pilot reporting. This does NOT cover every family, optimizer, platform, covariance-label mapping, interval calibration or real collaborator data. The unchanged bounded native/Julia parity fixture was rerun after the final source change; it passed all eight checks in 51.75 seconds without promoting a capability claim.

## Prose review

Self-review, 18 October 2026, whole report and dedicated README, for package contributors. Perceived AI-like style 2/10, medium confidence: the source hashes and explicit negative space make the claims inspectable. No repair needed for those passages. Science gate: pass for the generated covariance construction, checked against formulas and independent review. Facts gate: pass within the retained probes and source diff; platform outcomes remain pending. Reference gate: pass for issue and commit identifiers checked against GitHub and all-ref history. This is editorial self-review, not independent runtime validation.

## Profile warning follow-up

The final deterministic interpolation tests pass without warnings. The pre-fix pure fixture warned for repeated objective coordinates. The corrected method matches TMB at exact equality for unique coordinates, ties on both sides, repeated minima and outside-range thresholds; a separate analytic calculation verifies mean aggregation. Independent review found no blocking concern and confirmed these semantics against installed TMB 1.9.21. The broader affected profile/pilot suite passed without failures, errors or skips, with six existing deprecation warnings. Final pure interpolation tests passed nine assertions without warnings. The current-source checker passed all 12 negative mutation checks; freshness matched all 56 R and 95 Julia sources plus runner, with C14 unchanged and green. Exact outputs are retained in the dedicated log.
