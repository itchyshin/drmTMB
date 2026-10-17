# Staged uncertainty decision contract

Status: **frozen decision logic for independent review; not integrated into the full campaign summarizer and not authority to launch look two.** This note defines two pre-specified looks for the native Bernoulli SD-slope calibration. It does not change the response family, estimator, DGP, or calibration bands.

## Estimand and decision cells

For each truth value \(a \in \{-0.5, 0, 0.5\}\), the worker-level estimate is the fitted log-SD slope \(\hat a\). The reported derived scale contrast is \(\exp(\hat a)\), whose relative bias is \(\exp(\hat a-a)-1\).

The first look uses 1,000 planned attempts per truth (3,000 total). If it is ambiguous and all integrity and denominator checks pass, a second look may add 3,000 attempts per truth. The second look analyzes the cumulative 4,000 attempts per truth (12,000 total). It does not analyze only the additional subset.

## Frozen uncertainty rules

At each look, use two-sided 97.5% confidence intervals for each component metric. This is Bonferroni spending of 0.025 per look for the two repeated looks; it is not a joint simultaneous confidence statement across all truths and metrics.

- For each truth, the exact binomial interval for profile-interval coverage uses **all planned attempts**. A valid interval covers when it contains the generating slope; every invalid interval, failed fit without an interval, timeout, launch error, or not-started attempt is a noncoverage.
- At truth zero, the exact binomial interval for false positives also uses all planned attempts. A false positive is a valid profile interval that excludes zero. Invalid intervals are not counted as positive findings; the separate valid-fraction gate limits how many such attempts may occur.
- For each truth, the exact binomial interval for valid-interval fraction uses all planned attempts. Its lower endpoint must be at least 0.95.
- The Monte Carlo t interval for mean log-SD-slope bias (estimate minus truth) uses all finite estimates and reports that count. The t interval for relative exp(a) bias uses the same finite-estimate set. Each interval uses the two-sided 97.5% t critical value. Missing estimates are not replaced by zero; a non-finite transformed bias makes that metric undefined and therefore ambiguous.

The unchanged acceptance bands are coverage [0.925, 0.975], null false-positive rate [0.025, 0.075], log-SD bias [-0.10, 0.10], relative exp(a) bias [-0.10, 0.10], and valid-fraction lower limit at least 0.95.

## Decision rule

Before classifying metrics, the analyzer requires the exact look-specific manifest count and one row per planned attempt, with exactly 1,000 or 4,000 rows for each truth. An incomplete campaign returns **incomplete** and no decision. A campaign marked complete may contain only attempt-level `completed`, `error`, or `timeout` states; unresolved states such as `not_started`, `interrupted`, `campaign_timeout`, and `launch_error` contradict that receipt and return **integrity_failure**. A complete campaign with a mismatched denominator, unknown truth/status, invalid field types, or a valid interval paired with a non-completed status also returns **integrity_failure**. Integrity failures stop the decision; they are not model-fit failures. The full summarizer must preserve this distinction when mapping supervisor outcomes to the standardized helper input.

For a two-sided band, a gate **passes** when its entire confidence interval lies inside the band. It **fails** only when the interval lies wholly outside the band. Any overlap with a band boundary is **ambiguous**. The valid-fraction gate passes when its lower endpoint is at least 0.95, fails when its upper endpoint is below 0.95, and is otherwise ambiguous.

At look one, accept only if every gate passes; stop with failure if any gate fails; request look two only if the complete 3,000-attempt campaign has no failed gate and at least one ambiguous gate. At look two, accept only if every gate passes; stop with failure if any gate fails; otherwise report **inconclusive**. An ambiguous look-two result does not permit a third look.

Attempt quality is not collapsed into an automatic health failure. An attempt-level `error` or `timeout`, or a completed but unusable fit or interval, remains in the planned denominator, contributes no coverage, and reduces the valid fraction. A finite estimate may still contribute to a bias metric, with its finite-estimate denominator shown. The adapter must set the estimate to missing when no meaningful estimator was returned. Contradictory metadata is an integrity failure; poor numerical health by itself is handled through interval validity and the valid-fraction gate.

## Analyzer interface and boundary

The pure helper is tools/general-sd-regression/native-calibration/staged-decision.R. It accepts standardized columns truth, estimate, lower, upper, valid, and terminal status, together with manifest_count, look, and completed_campaign. It returns per-metric intervals, gate states, attempt-status counts, and one of accept, fail, look2_required, inconclusive, incomplete, or integrity_failure.

This helper does not authenticate manifest hashes, seeds, artifact hashes, worker identities, or the supervisor receipt. The existing full summarizer remains the future integration point for those checks; the legacy 95% summary is not input evidence for this decision. A future adapter must first reconcile every worker row to its manifest and supervisor state, then provide exactly one standardized row for each planned attempt.

## Look-two seed contract

The prepared look-two manifest is `docs/dev-log/general-sd-regression/stage-two-manifest.csv`, SHA-256 `8fd627ccb8a7f8689c56e629a5ff12e53405be1a508167216632bcf445652e96`. It contains replicate IDs 1001–4000 for each truth (9,000 additional attempts) and was produced by `tools/general-sd-regression/native-calibration/stage-two-seeds.R`: draw 10,000 candidates from master seed **2026101705**, remove all pilot, production-look-one, and qualification seeds, then take the first 9,000 remaining candidates. The producer must independently register and verify the file and seed disjointness during preparation. The look-two analyzer input combines all 3,000 look-one rows with all 9,000 new rows. This frozen manifest is not authorization to launch look two; its hashes, supervisor receipt, and cumulative row identity remain integration gates before any launch.

The user has approved the possibility of extending from 1,000 to 4,000 attempts per truth if Monte Carlo uncertainty remains inconclusive. This is not approval for an individual run over three hours; estimate runtime and present any required pre-run test before crossing that boundary. No campaign, fit, seed generation, remote launch, push, merge, email, or release is performed by this contract.
