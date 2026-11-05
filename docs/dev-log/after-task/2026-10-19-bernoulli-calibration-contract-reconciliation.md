# After Task: Bernoulli Calibration Contract Reconciliation

## 1. Goal

Reconcile the current Bernoulli calibration proposal with the approved plan, repair the component-level exact operating-characteristic calculation, and test the zero-truth denominator identity used by the staged decision helper.

## 2. Implemented

Restored the proposal's nominal 95% fitted profile-interval target and planned-attempt rate bands from the approved plan. Kept 97.5% exact intervals for Monte Carlo uncertainty at each look. Clarified that the completed 97.5% fitted-interval first look is exploratory and does not establish the approved target.

Corrected the exact component enumeration to handle the two disjoint failure tails created by two-sided bands. Updated its scenarios and results to match the approved coverage [0.925, 0.975] and false-positive [0.025, 0.075] bands. Added a regression test that checks, at zero truth, planned coverage plus planned false positives equals the valid fraction, including endpoint equality and invalid attempts.

## 3a. Decisions and Rejected Alternatives

The approved plan is the calibration design source for this work. A previous proposal revision switched the primary estimands to conditional-on-valid rates and moved the fitted interval target to 97.5%. That was inconsistent with the approved 95% fitted-interval target and the intended all-planned denominator. I corrected the proposal and did not alter the historical helper, worker, contract, or retained first-look artifacts.

The zero-truth coverage and false-positive counts are not simulated as independent rates. They are categories of the same planned attempts, alongside invalid attempts. The exact single-gate calculation remains a diagnostic and does not substitute for a dependent campaign analysis.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/prospective-bernoulli-calibration-proposal.md`: aligned candidate design and estimands with the approved plan.
- `tools/general-sd-regression/calibration-binomial-oc.R`: corrected two-sided count-range handling and approved scenarios.
- `docs/dev-log/general-sd-regression/calibration-binomial-oc.md`: corrected results, scope, and zero-truth identity.
- `docs/dev-log/general-sd-regression/native-calibration-design.md`: clarified the difference between fitted interval level and Monte Carlo interval level.
- `tools/general-sd-regression/native-calibration/test-staged-decision.R`: added the zero-truth partition regression test.
- `docs/dev-log/check-log.md`: recorded the correction and evidence.
- This report records the checkpoint.

## 5. Checks Run

- `Rscript tools/general-sd-regression/calibration-binomial-oc.R`: passed all enumerated scenarios, state checks, two-tail checks, and probability-mass checks. The deterministic run took about 9 seconds.
- `Rscript -e 'library(testthat); test_file("tools/general-sd-regression/native-calibration/test-staged-decision.R", reporter = "summary")'`: passed with no failures.
- Lane preflight found no foreign missing-ref work on the proposal, component analysis, native calibration design note, or staged-decision test path. The after-task report path was new.
- The after-task structure check passed; the prose linter reported zero findings for the proposal, component analysis, native design note, and this report. Scoped `git diff --check` and the targeted trailing-whitespace scan passed for the implementation and report paths.
- No model fits, profile runs, Julia runs, or remote compute were started.

## 6. Tests of the Tests

The component script asserts that both low and high failure tails exist for the two-sided coverage and FPR bands, and that look-one and final outcome probabilities sum to one. The staged-helper regression includes exact-zero interval endpoints and invalid attempts, then checks the count and rate partition identities. The result tests a mathematical invariant rather than repeating a fitted model implementation.

## 7a. Issue Ledger

The read-only search `gh issue list --repo itchyshin/drmTMB --state open --search 'random effect SD calibration Bernoulli' --json number,title,url --limit 20` returned no matching open issue. No issue was created or changed.

## 8. Consistency Audit

The proposal now distinguishes 95% fitted profile intervals from 97.5% Monte Carlo uncertainty intervals. The component analysis and proposal use the approved planned-denominator bands. The frozen staged helper remains unchanged, and the completed 97.5% first-look output remains exploratory. The complete campaign gate vector still needs a dependence-aware operating-characteristic analysis before any confirmatory seeds are prepared.

## 9. What Did Not Go Smoothly

My first corrective proposal retained conditional rates and a 97.5% fitted-interval target, despite the approved plan specifying 95% fitted intervals and planned denominators. I caught and corrected that mismatch before treating the proposal as a simulation specification. The initial rerun of the component script also failed because its range logic assumed one contiguous failure set; two-sided bands require separate tail ranges. The corrected implementation now sums them separately.

## 10. Known Residuals

This work does not establish uncertainty calibration for the fitted Bernoulli model. The complete two-look campaign-level OC, with the joint coverage, validity, false-positive, and bias outcomes, is outstanding. The status of both bias metrics as acceptance gates needs independent review. The 97.5% fitted-interval first look cannot be reused to calibrate the approved 95% target. Julia calibration and every broader family, random-effect, endpoint, and provider combination remain open.

## 11. Team Learning

Before extending a calibration campaign, compare the current worker's fitted interval level with the user's approved target and distinguish it from the Monte Carlo interval level used to assess coverage. For multi-category outcomes, derive and test their algebraic identities before assuming independent component rates.

## 12. Cross-Product Coverage

This checkpoint changes no runtime fitting behavior. It does NOT cover the Julia engine, new response families, additional random-effect providers, non-Bernoulli calibration, public output parity, or release behavior. It updates only the prospective native Bernoulli calibration evidence and a pure helper invariant test.
