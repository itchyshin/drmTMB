# After Task: conditional look-two OC reporting

## 1. Goal

Distinguish the unconditional campaign probability of each second-look outcome from the probability conditional on a campaign reaching look two.

## 2. Implemented

The synthetic OC harness reports look-two acceptance, failure, and inconclusive probabilities with two denominators. Exact 95% binomial intervals use the matching denominator. Conditional estimates are `NA` when no campaign reaches look two. The design note documents the independent truth-stratum assumption and the dependence represented within each attempt.

## 3a. Decisions and Rejected Alternatives

Kept unconditional probabilities because they answer the chance of the full pathway reaching and ending in each look-two outcome. Added conditional probabilities because they answer what happens after continuation. Did not report conditional rates as zero when no campaigns continued; those estimands are unavailable in that case. Assumption made without asking: truth strata are independent datasets without shared cross-truth shocks, matching the harness's existing data generation. If that assumption is wrong, the OC generator needs a shared-shock scenario.

## 4. Files Touched

- `tools/general-sd-regression/campaign-oc.R`
- `tools/general-sd-regression/test-campaign-oc.R`
- `docs/dev-log/general-sd-regression/campaign-oc-design.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-19-campaign-oc-conditional-reporting.md`
- `docs/dev-log/after-task/2026-10-19-campaign-oc-conditional-reporting.assessment.json`
- `evidence/campaign-oc-conditional-20261019/output.txt`
- `evidence/campaign-oc-conditional-20261019/stderr.txt`
- `evidence/campaign-oc-conditional-20261019/receipt.txt`
- `evidence/campaign-oc-conditional-final-20261019/output.txt`
- `evidence/campaign-oc-conditional-final-20261019/stderr.txt`
- `evidence/campaign-oc-conditional-final-20261019/receipt.txt`

## 5. Checks Run

- `Rscript tools/general-sd-regression/test-campaign-oc.R`: pass, all focused tests.
- `Rscript tools/general-sd-regression/campaign-oc.R 100 20261023`: final-source exit 0, 16.160 seconds, R 4.6.0, no fitted models. Output, hashes, and environment receipt are retained under `evidence/campaign-oc-conditional-final-20261019/`. The earlier receipt under `evidence/campaign-oc-conditional-20261019/` is preserved from before the malformed-label guard.
- Contract readback: `docs/dev-log/general-sd-regression/staged-calibration-contract.md` specifies 95% fitted profile intervals and 97.5% Monte Carlo intervals; `worker-095.R` requests `confint(level = 0.95)`.
- Independent review withdrew its earlier 97.5%-worker concern after reading the current contract and recommended conditional look-two summaries.
- `git diff --check` on tracked changes: pass.
- `check-after-task.R` with the report's absolute path: structure check passed. `slop_check.py`: 0 findings. Separate whole-report style assessment: 2/10, confidence medium; science and facts gates pass, references not applicable. Exact-draft record is in the adjacent `.assessment.json` file.
- `bash "/Users/z3437171/Dropbox/Github Local/Shinichi/tools/lane_preflight.sh" --file` reported no missing work on the two harness paths. The design-note preflight emitted no path verdict; no inference is drawn from that absent output.

## 6. Tests of the Tests

The added test first failed because `summarize_look2_outcomes()` did not exist. After implementation, tests checked the `NA` conditional rate and the zero unconditional rate with a positive upper exact limit when no campaign continues. An independent review identified the latter missing assertion. A malformed-label test then failed before the new validation guard and passed after it. The focused suite passed after both changes.

## 7a. Issue Ledger

Focused open-issue searches for Bernoulli random-effect SD calibration, predictor-dependent random-effect scale, and `sd(group)` random effects returned no matching issue. No issue was opened, commented on, or changed.

## 8. Consistency Audit

The output names distinguish `_probability` from `_given_look2_probability`; exact intervals use all campaigns for unconditional rates and the continuation count for conditional rates. The design note states that truth strata are independently generated and that within-attempt dependence comes from a shared estimation error. This change affects internal simulation reporting only, so no public formula, family-support, README, NEWS, roadmap, limitations, or pkgdown claim changed. The active staged-calibration contract and historical 97.5% fitted-interval evidence remain distinct.

## 9. What Did Not Go Smoothly

The first report draft used an older package template and failed the current structural checker. I replaced its headings with the executable 12-section format. The shared `closeout.py` resolves paths against the Shinichi brain repository, so I did not use it to create or write this package report; its check remained blocked in that unrelated repository's evidence gate and was stopped after 30 seconds. Direct R validation of this report passed using its absolute path. The initial smoke receipt was preserved, and a final-source smoke was run after the malformed-label guard changed the harness hash.

## 10. Known Residuals

The harness uses synthetic attempts and does not fit models. It does NOT establish fitted profile calibration, Bernoulli parameter recovery, chosen thresholds, the broader distribution-family universe, Julia parity, or a feature-level inference claim. The cross-truth independence assumption excludes shared shocks across truth strata. The new reporting fields were exercised in a 100-campaign smoke; no new 1,000-campaign run was conducted.

## 11. Team Learning

When a staged simulation reports later-stage outcomes, show both the full-campaign probability and the probability conditional on reaching that stage. Use the correct denominator for each interval.

Memory receipt: `route.py` returned no LOAD-FIRST manifest for this repository, so no routed project notes shaped this bounded reporting change. The user-provided project AGENTS instructions and the current staged-calibration contract were used.

Golden Set: not in scope; this task changes synthetic OC reporting, not model or formula behavior.

## 12. Cross-Product Coverage

Covers: the R script's synthetic Bernoulli two-look decision-rule summaries and their denominator-specific Monte Carlo intervals.

Does NOT cover: fitted R/TMB results, any Julia engine, other distributions, random-effect types, structured covariance, profile calibration, parameter recovery, thresholds, or package-level feature support.
