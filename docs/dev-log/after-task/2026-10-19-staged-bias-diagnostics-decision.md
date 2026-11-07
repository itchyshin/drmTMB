# After Task: Bernoulli Bias Diagnostics in the Staged Calibration Rule

## Goal

Remove unvalidated t intervals for mean log-SD bias and relative `exp(a)` bias from the Bernoulli staged acceptance decision while keeping those summaries visible.

## Implemented

`native_sd_staged_decision()` now bases staged acceptance on planned-denominator interval coverage, null planned-denominator false-positive rate, and interval validity. It continues to report both bias intervals with their finite-estimate denominators, but they have no gate state. The summarizers label bias as diagnostic-only and omit the old bias-threshold flags.

Any future acceptance under this rule would be limited to interval behavior and availability under the declared synthetic domain. No eligible fitted-model calibration result currently exists, and the rule does not establish point-estimator recovery. The broader multi-family, random-effect, and Julia programme remains open.

## Mathematical Contract

The two-look component intervals for coverage, false-positive rate, and validity retain their 97.5% Monte Carlo confidence level. The all-gates decision is an intersection-union rule over these criteria, with Bonferroni allocation across the two looks. Bias t intervals remain conditional on finite returned estimates and unvalidated for skew, rare tails, and outcome-dependent missing estimates. They are descriptive only.

## Files Changed

- `tools/general-sd-regression/native-calibration/staged-decision.R`: removed log-SD and relative-scale bias rows from the qualifying gate table; retained their metric rows.
- `tools/general-sd-regression/native-calibration/test-staged-decision.R`: added a regression test showing that a 0.20 bias does not veto otherwise passing interval criteria; retained diagnostics and finite-estimate denominator checks.
- `tools/general-sd-regression/native-calibration/summarize.R`, `summarize-095.R`, and `summarize-0975.R`: mark bias as diagnostic-only and remove bias-threshold flags.
- `tools/general-sd-regression/native-calibration/self-test.py`: verify the summary labels and allow up to 120 seconds for the 3,000-file summarizer fixture.
- `tools/general-sd-regression/native-calibration-stage-two/` tests: checked first-look replay rejection and stage-two rule behavior against the new gate table.
- `docs/dev-log/general-sd-regression/staged-calibration-contract.md`, `native-calibration-design.md`, `campaign-oc-design.md`, `calibration-binomial-oc.md`, and `prospective-bernoulli-calibration-proposal.md`: distinguish qualifying criteria from bias diagnostics, label the superseded seed manifest, and preserve historical decisions as historical.
- `docs/dev-log/after-task/2026-10-19-campaign-oc-harness.md`: identify the earlier bias gates as superseded by the current reviewed rule.
- `docs/dev-log/general-sd-regression/evidence/campaign-oc-bias-diagnostics-20261019/`: retains the 1,000-campaign rule-level run, elapsed time, output, and source hashes.
- `docs/dev-log/check-log.md`: records commands, outcomes, and scope.
- This report records the after-task audit.

## Checks Run

- `Rscript --vanilla -e 'testthat::test_file("tools/general-sd-regression/native-calibration/test-staged-decision.R")'`: passed, 35 assertions. The new test failed before the helper change because the old rule returned `fail` solely from the bias gate.
- `OPENBLAS_NUM_THREADS=1 Rscript --vanilla tools/general-sd-regression/test-campaign-oc.R`: passed.
- `OPENBLAS_NUM_THREADS=1 python3 tools/general-sd-regression/native-calibration/self-test.py`: passed. This covers analyzer, summary identity, manifest, DGP, supervisor, and cleanup checks.
- `Rscript --vanilla tools/general-sd-regression/native-calibration-stage-two/test-verify-first-look-registry.R`: passed.
- `Rscript --vanilla tools/general-sd-regression/native-calibration-stage-two/test-combine-stage-two.R`: passed; its subprocess emitted a `system2()` warning while correctly rejecting the legacy first-look fixture before any fits.
- `Rscript --vanilla tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R tools/general-sd-regression/native-calibration-stage-two`: passed.
- `Rscript --vanilla tools/general-sd-regression/campaign-oc.R 1000 20261022`: passed for 1,000 campaigns per scenario in 157.18 seconds. The nominal scenario had 855 acceptances, 145 inconclusive outcomes, and no failures. This is synthetic decision-rule evidence, not fitted-model evidence.
- `gh issue list --repo itchyshin/drmTMB --state open --search 'Bernoulli SD calibration' --json number,title,url --limit 20`: returned no matches.

The full package suite, pkgdown build, fitted-model recovery campaign, and live Julia calibration were not run.

## Tests Of The Tests

The new test first failed against the old decision rule, then passed after the bias rows were removed from `gates`. It checks both the decision and the retained bias metric. The self-test also confirms the CSV summary carries `bias_diagnostics_only=TRUE` and no longer emits bias-threshold flags. The campaign-OC test checks reproducibility, outcome partitions, and the staged stopping rule.

## Consistency Audit

The staged contract, proposal, native calibration design, campaign-OC note, and exact component analysis now agree that bias intervals are diagnostics. Historical after-task reports retain their contemporaneous results but identify the superseded bias-gate rule. The old look-two seed manifest is explicitly labeled historical. The project status inventory still marks fitted interval calibration and broad family coverage open. Formula grammar and package behavior did not change.

The exact searches were:

```sh
rg -n -i --glob '!evidence/**' --glob '!*.csv' --glob '!*.json' 'bias.{0,45}(gate|accept)|((gate|accept).{0,45}bias)' docs/dev-log/general-sd-regression docs/dev-log/after-task tools/general-sd-regression/native-calibration
rg -n -i 'sd\(.*\)|Bernoulli|calibrat|bias' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

## GitHub Issue Maintenance

No matching open Bernoulli SD-calibration issue was found. No issue was created, edited, or closed.

## What Did Not Go Smoothly

The first campaign-OC test invocation used `testthat::test_file()` from a directory where it missed the test script. The repository-root command passed. The calibration self-test's 30-second timeout was too short for its 3,000-file summary fixture; raising it to 120 seconds allowed the complete test to pass. One initial stage-two rules invocation omitted its required adapter-directory argument and was rerun correctly.

## Team Learning

An approximate t interval for raw bias can look precise after a rare tail is missed. A separate valid-fraction gate does not repair bias estimation conditional on finite returned fits. Acceptance should use criteria with justified finite-sample behavior; unvalidated bias summaries remain visible without controlling that decision.

## Known Limitations

No current-source fitted Bernoulli interval-calibration run is eligible under the frozen seed and 95% profile-level requirements. This rule-level simulation does not calibrate profile intervals or point-estimator recovery. The 19,118-row family and random-effect ledger, native/Julia parity, and all broader endpoint and provider combinations remain incomplete.

## Next Actions

Keep the Bernoulli inference gate open until a clean-seed 95%-profile fit campaign has valid source and result receipts, and separately specify and assess point-estimator recovery. Continue the wider family and random-effect mapping without presenting this decision-rule change as evidence of Julia parity or full calibration.
