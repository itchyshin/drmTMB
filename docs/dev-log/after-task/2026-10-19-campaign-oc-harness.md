# After Task: Synthetic Campaign-Level Bernoulli OC Harness

## 1. Goal

Exercise the frozen two-look Bernoulli calibration decision rule under joint synthetic attempt outcomes, without claiming fitted-model calibration.

## 2. Implemented

Added a deterministic-seed simulator that generates all-planned attempt rows for the three frozen truths, calls the existing staged helper at look one, and adds an independent second-look batch only when the helper requests it. It reports the joint campaign outcomes, expected planned attempts, and pointwise exact Monte Carlo intervals for outcome proportions.

## 3a. Decisions and Rejected Alternatives

At the time of this harness report, the helper treated profile interval validity, coverage, false positives, log-SD bias, and relative `exp(a)` bias as gates. That bias-gate description is superseded by the reviewed contract in `staged-calibration-contract.md`: bias intervals are now diagnostics only. The two-look design remains 1,000 attempts per truth at look one and cumulative 4,000 per truth at look two. At zero truth, coverage and false positives share one interval, so their planned counts plus valid count partition exactly. Synthetic intervals are fixed-width normal-error intervals; they are not profile likelihood intervals. A campaign-level simulation was chosen over multiplying independent gate probabilities because its stages and dependent outcomes must be evaluated together.

## 4. Files Touched

- Added `tools/general-sd-regression/campaign-oc.R`.
- Added `tools/general-sd-regression/test-campaign-oc.R`.
- Added `docs/dev-log/general-sd-regression/campaign-oc-design.md`.
- Retained the 100-campaign stdout and source-hash receipt under `docs/dev-log/general-sd-regression/evidence/campaign-oc-20261019/`.
- Updated `docs/dev-log/check-log.md`.

## 5. Checks Run

- `Rscript tools/general-sd-regression/test-campaign-oc.R`: all four tests passed.
- `Rscript tools/general-sd-regression/campaign-oc.R 100 20261019`: six scenarios completed in 7.52 seconds on R 4.6.0.
- The nominal scenario returned 78 accepts, 0 failures, and 22 inconclusive campaigns; 97 of 100 required look two. The deliberate poor-coverage, low-validity, bias, and boundary scenarios failed as designed. Informative invalidity produced 52 early failures, 48 second looks, 99 final failures, and 1 inconclusive result.
- `git diff --check` on the new source and design paths passed.
- `slop_check.py` on the design note returned FINDINGS: 0.

## 6. Tests of the Tests

Fixed seeds verify exact reproducibility. The tests check that the three final outcomes partition every simulated campaign, planned attempts stay within the two permitted totals, zero-truth coverage plus false positives equals valid attempts, and informative invalidity is correlated with estimation error. A direct single-campaign test confirms the frozen helper controls both look transitions.

## 7a. Issue Ledger

No open issue was modified. This internal harness evaluates a pre-existing calibration rule and does not resolve or close a user-facing support issue.

## 8. Consistency Audit

The simulator sources and calls the existing helper without editing it. The design note states the assumptions and distinguishes Monte Carlo uncertainty from the feature's fitted-interval calibration. This slice changes no formula, likelihood, family admission, public API, example, or pkgdown navigation; the broader feature status inventory therefore remains unchanged and G2/G5 remain open.

## 9. What Did Not Go Smoothly

The prose checker initially interpreted the relative worktree path under the primary checkout and could not find the new file. Passing its absolute path resolved the issue. The report checker also caught that the project requires a numbered 12-section format, so the report was revised and rechecked. The simulator output shows that the nominal joint campaign can frequently remain inconclusive after the first look, even when the marginal targets are nominal; more campaign replicates would be needed to narrow those Monte Carlo estimates.

## 10. Known Residuals

This is a synthetic decision-rule stress test. It does not fit Bernoulli models, calculate profile likelihoods, establish recovery or interval coverage, or count toward the approved fit-based calibration denominators. Normal errors, fixed interval widths, and the six named scenarios are illustrative assumptions. The 100-campaign pilot has wide Monte Carlo uncertainty and is not a final qualification result. No Totoro, DRAC, or Julia compute ran.

## 11. Team Learning

Model joint attempt outcomes and replay the actual campaign decision rule. Separate marginal-gate calculations cannot reveal the campaign's early-stop, continuation, and inconclusive probabilities.

## 12. Cross-Product Coverage

Only the native Bernoulli decision-rule helper was exercised. This slice does NOT cover the Julia engine, other response families, random-effect types, package fit methods, or public outputs. No parity or general-support claim follows from this slice.

## Next Actions

Use the harness to refine a predeclared campaign design, then validate the approved 95% fitted-interval target with independent Bernoulli model fits. Resume shared compute only after the DRM.jl Totoro lane confirms the host is free. Continue the programme ledger; no overall completion claim is made.
