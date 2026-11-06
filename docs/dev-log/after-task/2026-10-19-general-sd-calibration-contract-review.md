# After Task: Bernoulli SD Calibration Contract Review

## 1. Goal

Clarify the inference limits of the staged Bernoulli SD-slope calibration rule and bind an updated synthetic operating-characteristic run to the exact current source.

## 2. Implemented

- The staged contract now labels bias as conditional on finite returned estimates and the t intervals as approximate, especially for relative bias after exponentiation.
- It distinguishes planned false-positive probability from conditional type-I error among valid intervals and records the inference review's conclusions about the two-look and intersection-union logic.
- It records the rare-tail counterexample as a stress construction, not as a claim about the fitted estimator.
- The campaign design now links the current-source rerun and limits its interpretation.
- Ran and retained 1,000 campaigns for each of 11 synthetic scenarios with seed `20261020`; output and exact source hashes are in `docs/dev-log/general-sd-regression/evidence/campaign-oc-inference-review-20261019/`.

## 3a. Decisions and Rejected Alternatives

- Kept the staged decision algorithm and acceptance bands unchanged. The reviewer found the two-look logic defensible conditional on marginal interval coverage; the unresolved defect is that bias-interval coverage under skew, rare tails, and informative missingness has not been demonstrated.
- Did not present the synthetic OC result as fitted-model calibration or authority to launch look two.
- Assumptions made without asking: the local 1,000-campaign rerun is useful as a source-hash-bound OC receipt while the bias-interval review remains open. If this is not the intended role, keep the result as exploratory evidence and remove the campaign-design summary paragraph.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/staged-calibration-contract.md`
- `docs/dev-log/general-sd-regression/campaign-oc-design.md`
- `docs/dev-log/general-sd-regression/evidence/campaign-oc-inference-review-20261019/output.txt`
- `docs/dev-log/general-sd-regression/evidence/campaign-oc-inference-review-20261019/receipt.txt`
- `docs/dev-log/after-task/2026-10-19-general-sd-calibration-contract-review.md`

## 5. Checks Run

- `Rscript --vanilla -e "testthat::test_file('tools/general-sd-regression/native-calibration/test-staged-decision.R')"`: PASS, 30 assertions, 0 failures, 0 warnings, 0 skips.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript --vanilla tools/general-sd-regression/campaign-oc.R 1000 20261020`: PASS, 11,000 synthetic campaigns total; approximately 2 minutes locally. No model fits were run.
- Source and output SHA-256 values were recorded in `receipt.txt`; the campaign script hash is `b68b4e1533ddc20b15ae6c488f27ce49fd5cffe458a5e939fe1d02908f80c35a`, helper hash is `c4aeff17732529febbf6a00ca8ba963c188a1b5e935c6be76cecb49c680ba3c9`, and output hash is `0eb55bd623631d81dc279d6dfc6a8bf3a66f40768355d6d33b3bfbbbfc930e6c`.
- `git diff --check` on the touched contract and evidence paths: PASS.
- `python3 ~/shinichi-brain/tools/slop_check.py <absolute staged-calibration-contract.md>`: PASS, 7 findings / 1,546 words = 4.5 per 1,000; 0 em dashes.
- `python3 ~/shinichi-brain/tools/lane_preflight.sh --file ...` for the contract, campaign design, and new output path showed no missing foreign edits; the shared `docs/dev-log/check-log.md` preflight stalled and was interrupted without editing that file.

## 6. Tests of the Tests

The existing staged-decision tests exercise acceptance, failure, ambiguity, denominator integrity, and invalid-attempt handling. The direct `Rscript` invocation first failed because `test_that()` was not attached; running the file through `testthat::test_file()` executed all 30 assertions. The OC simulation invokes the actual staged-decision helper unchanged for each synthetic campaign. It tests the decision-rule implementation under its declared stylized inputs, not whether the fitted estimator generates those inputs.

## 7a. Issue Ledger

- Bias interval coverage under skewed errors, rare tails, and outcome-dependent finite-estimate missingness: open; required before calling staged acceptance calibrated.
- Current-source OC output: completed and hash-bound; exploratory synthetic evidence only.
- No GitHub issue was changed. This milestone changes internal calibration interpretation and does not add or announce public model support.

## 8. Consistency Audit

The staged contract, campaign design, and retained output now agree on the scope of the current-source OC run. The fit-based calibration remains unqualified, look two remains unauthorized, and no feature-level uncertainty claim is made. Existing distribution, formula, engine, and public API inventories were not re-audited in this milestone. NotebookLM review is still pending because its connector reports an expired session and a signed-out page.

Memory receipt: the repository's LOAD-FIRST route and `drmTMB` project instructions were consulted; the staged-calibration contract and inference review shaped the work. No matching Golden Set mistake class was changed, so no Golden Set edit was made. The DRM.jl lane was checked and remains on a separate CJS diagnostic; no shared source edit was made there.

## 9. What Did Not Go Smoothly

The prior OC receipt named a different campaign-script hash. A fresh run now binds output to the current source. The shared check-log preflight again stalled; it was stopped, and `docs/dev-log/check-log.md` remains untouched by this milestone. NotebookLM authentication remains unavailable through the connector.

## 10. Known Residuals

No Bernoulli fitted-model recovery or interval-calibration result is established here. The 1,000-campaign OC run does not challenge the rare-tail counterexample, informative missingness among finite estimates, or profile interval coverage. The staged helper is not integrated into the full campaign summarizer and does not authorize look two. Broader Julia parity, other families, random-effect types, and provider coverage remain open under the active general-SD goal.

## 11. Team Learning

Keep the decision-rule logic separate from interval validity. A correct sequential rule cannot make approximate bias intervals calibrated; qualify the interval construction and the estimand before interpreting an accept result. Record current source hashes with every retained synthetic OC output.

## 12. Cross-Product Coverage

- Covers: native Bernoulli staged-decision helper behavior under 11 stylized synthetic attempt distributions; contract and internal documentation for staged uncertainty interpretation.
- Does NOT cover: fitted Bernoulli recovery or interval calibration; rare-tail or informative-missingness robustness; Julia; other response families; structured or correlated random effects; prediction, extraction, save/reload, profiling, or bootstrap outputs; Totoro or DRAC campaigns; NotebookLM methods synthesis; look-two authorization; public support or release claims.
