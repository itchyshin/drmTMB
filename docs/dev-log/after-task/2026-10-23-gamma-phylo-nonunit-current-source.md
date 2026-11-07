# After Task: Reverify Gamma Phylogenetic SD Parity on Current Sources

## 1. Goal

Rerun the existing non-unit-height Gamma phylogenetic SD bridge test against the current native and Julia candidates because the earlier run's source hashes no longer matched.

## 2. Implemented

No product code or test code changed. The existing test passed 6 assertions through one live R-to-Julia bridge fit on current sources; a new source manifest and console log preserve the result.

## 3a. Decisions and Rejected Alternatives

Kept the earlier source-bound receipt intact and recorded this run separately. Retained Julia's raw branch-length-scale warning; no kernel normalization or public support change was made.

## 4. Files Touched

Added a current-source evidence directory, check-log receipt, and this report. Updated the shared checkpoint and check log with the bounded rerun result.

## 5. Checks Run

- Focused command in the source manifest: exit code 0; 6 assertions passed; one live Julia bridge test ran.
- Julia reported raw branch-length scale for a tree with maximum tip height 6.404475. No other warning appeared in the captured console.
- The after-task structure validator passed. It reported the programme acceptance ledger as not runnable in this environment, so its gate state remains unknown.
- `slop_check.py` reported 0 findings for this report.

## 6. Tests of the Tests

The existing fixture uses a fixed seed, asserts tree height greater than one, verifies convergence and coefficient names, and compares same-data coefficient and tip-level SD predictions at tolerance 1e-3. The run has a source manifest and captured console. It has no independent likelihood oracle or coverage study.

## 7a. Issue Ledger

The prior focused issue search found only #555, an unrelated Ayumi q4 Gaussian workflow. No issue was changed for this source-hash rerun.

## 8. Consistency Audit

The test, source manifest, and captured output agree on the two candidate heads, the test file, one live fit, six assertions, and the raw-scale warning. The old report remains historical; this rerun supersedes its source pin for current-candidate evidence. No user-facing guide or pkgdown page changed.

## 9. What Did Not Go Smoothly

The first rerun stopped before fitting because Julia was absent from the shell `PATH`. Adding the installed Julia 1.10 executable path allowed the test to complete. A subsequent captured rerun provided an explicit exit code and retained the full output.

## 10. Known Residuals

This is one Gamma phylogenetic-intercept parity fixture on an ultrametric tree. It does NOT establish arbitrary tree scaling, non-ultrametric behavior, other providers or families, recovery, simulation, saved-object workflows, or interval calibration. Julia's raw branch-scale warning is an interpretation boundary, not a claim that the latent SD is on the correlation scale.

## 11. Team Learning

For live Julia bridge checks, add the installed Julia path explicitly when the shell does not expose it; preserve the process exit code and console alongside source hashes.

## 12. Cross-Product Coverage

This check covers native TMB and the Julia bridge for one Gamma `mu` phylogenetic random intercept, with a fixed predictor on its SD formula and same-data coefficient and tip-level prediction comparisons. It does NOT cover other response families, random-effect providers or shapes, direct standalone Julia calls, uncertainty calibration, package-wide checks, or current-main integration. The required-row ledger and full programme gates remain open.
