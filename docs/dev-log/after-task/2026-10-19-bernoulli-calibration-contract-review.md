# After Task: Bernoulli Calibration Contract Review

## 1. Goal

Assess whether the proposed Bernoulli random-effect SD calibration rule is ready to freeze, and reconcile the current implementation inventory with retained evidence.

## 2. Implemented

Added an exact count-enumeration analysis of the candidate one-component binomial gates and recorded the independent review findings. Updated the proposal to distinguish the all-components conjunction from separate cell claims, retain the planned-attempt validity rule, and keep the margins and sample schedule provisional. Updated the active-worktree section of the inventory while preserving its pinned-source counts and the 19,118-row obligation ledger.

## 3a. Decisions and Rejected Alternatives

The exact single-gate calculation is retained as diagnostic evidence, not used to select or freeze acceptance margins. The completed exploratory first look is not reused to tune thresholds or to count toward a future confirmatory look. The candidate full calibration rule remains open pending joint operating-characteristic analysis and maintainer review.

## 4. Files Touched

The numerical analysis enumerates all possible counts for a single binomial rate under a two-sided 97.5% Clopper-Pearson interval at look one (1,000 attempts) and cumulatively at look two (4,000 attempts). It models a gate that continues only when its own first-look result is ambiguous. It does not model the actual campaign-wide continuation rule, dependence among metrics, bias gates, or fitted-model variability. Therefore, it cannot freeze the full design.

The candidate claim is limited to each predeclared ordinary-condition component meeting its margin, with global acceptance requiring every component to pass. Marginal component intervals are not simultaneous intervals. Separate cell-specific claims require a multiplicity policy. Failed intervals remain noncoverage in the all-planned denominator, do not count as false positives, and must satisfy a separate validity gate. These are provisional pending maintainer approval.

- `tools/general-sd-regression/calibration-binomial-oc.R`: exact single-gate operating-characteristic enumeration.
- `docs/dev-log/general-sd-regression/calibration-binomial-oc.md`: results and limitations.
- `docs/dev-log/general-sd-regression/prospective-bernoulli-calibration-proposal.md`: revised provisional claim and gate requirements.
- `docs/dev-log/general-sd-regression/native-calibration-design.md`: corrected status of the completed exploratory first look.
- `docs/dev-log/general-sd-regression/inventory.md`: current candidate evidence snapshot, separate from pinned-source counts.
- `docs/dev-log/check-log.md`: this review's check receipt.
- This report records the review boundary.

## 5. Checks Run

- `Rscript tools/general-sd-regression/calibration-binomial-oc.R`: passed. Count-state probabilities summed to one for each enumerated case.
- Two independent inference reviews agreed that the enumeration is correct for a single gate and that it does not establish the global staged campaign's operating characteristics.
- The inventory audit retained 19,118 required rows: 11,198 unresolved, 4,399 required, 3,431 blocked by base plumbing, and 90 structurally inapplicable. All rows remain `direct_sd_claim=none`.
- Full package tests were not rerun; the current focused regression result remains the separate 645-assertion run with nine live-Julia tests skipped, as recorded in the inventory and check log.

## 6. Tests of the Tests

The script checks that enumerated state sets are contiguous and that probability mass sums to one at both looks. Reviewers independently checked the single-gate enumeration and its interpretation. This does not validate the campaign-wide rule or the Monte Carlo calibration pipeline.

## 7a. Issue Ledger

`gh issue list --repo itchyshin/drmTMB --state open --search 'random effect SD calibration Bernoulli' --json number,title,url --limit 20` returned no matches. No issue was created, closed, or updated.

## 8. Consistency Audit

The inventory now labels its old source inventory as historical and distinguishes candidate code presence, focused tests, live Julia execution, and calibration. The corrected native first-look result remains exploratory and is not treated as calibration. The broader required ledger remains unchanged. The proposal and operating-characteristics note both state that the candidate analysis is insufficient to freeze thresholds or launch confirmatory fits.

## 9. What Did Not Go Smoothly

The candidate one-sided bands accept arbitrarily conservative rates, and the observed first-look coverage is close to a proposed margin. Independent review therefore found the candidate margins and sample schedule insufficiently justified. The exact component analysis clarified this limitation but cannot resolve joint campaign behavior without the complete gate vector and dependence structure.

## 10. Known Residuals

The calibration contract is not frozen. The full campaign-wide two-look operating-characteristic analysis, the status of bias as an acceptance gate, the conditional false-positive reporting rule, and independent maintainer approval remain outstanding. No new model fits or shared-compute jobs were run. The 19,118-row implementation programme remains far from complete, and no broad family or Julia-parity claim is established.

## 11. Team Learning

Operating-characteristic calculations must match the actual stopping rule and the claim being made. Per-gate calculations are useful diagnostics, but they cannot stand in for a multi-gate campaign when all metrics share fitted attempts.

## 12. Cross-Product Coverage

This review changes no runtime product behavior. It updates evidence and planning for the native R/TMB and Julia Bernoulli SD-regression validation programme. It does NOT cover a new runtime engine, public API, distribution family, random-effect provider, or downstream package behavior. Live Julia calibration, full family/effect parity, and the other distributional endpoints remain unverified or incomplete as recorded in the inventory.

## Next Actions

Specify the complete gate vector and simulate the full two-look decision rule while preserving attempt-level dependence. Report global pass, fail, and inconclusive probabilities under nominal, boundary, and departure scenarios, alongside planned and valid-only false-positive rates. Obtain independent review before freezing a fresh-seed confirmatory plan. Keep G2 open until implementation-specific recovery and uncertainty gates pass on both engines.
