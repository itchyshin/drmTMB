## 1. Goal

Determine whether the native Bernoulli random-effect SD regression implementation has calibrated 95% profile intervals under the frozen clean-current first-look design, while retaining every attempted fit and keeping the decision rule unchanged.

## 2. Implemented

- Ran the clean-current first-look campaign on Totoro with three truth values for the log-SD slope: -0.5, 0, and 0.5, with 1,000 attempts per value.
- Retained the campaign archive, standalone summary, supervisor receipt, source registry, and pre-run qualification outputs.
- Fixed exact-basename matching in the clean-current launcher and worker so manifest.csv no longer collides with stage-two-manifest.csv. Added a regression test for that collision.
- Recorded the staged decision as look2_required. This first-look campaign did not launch a second look.

## 3a. Decisions and Rejected Alternatives

The first look is a decision-stage result; overall qualification remains false. The true-slope -0.5 coverage and the null coverage and false-positive gates are inconclusive under the predeclared Monte Carlo bands. The true-slope 0.5 coverage gate passes. Because the staged decision is look2_required, overall qualification remains false.

The Monte Carlo intervals are 97.5% intervals for the two-look procedure; the fitted profile intervals are 95%. Bias summaries remain descriptive diagnostics and do not enter the decision. The second look requires source-adapter reconciliation and separate compute authorization. This work does not authorize that run.

## 4. Files Touched

- tools/general-sd-regression/native-calibration/run-095.py
- tools/general-sd-regression/native-calibration/worker-095.R
- tools/general-sd-regression/native-calibration/test-clean-current-route.py
- docs/dev-log/check-log.md
- docs/dev-log/after-task/2026-10-19-bernoulli-sd-first-look-calibration.md
- docs/dev-log/general-sd-regression/evidence/calibration-20261019/current-source-bern-095-first-look-v4/

The package likelihood implementation was not changed in this calibration slice.

## 5. Checks Run

- The full first-look campaign completed 3,000 of 3,000 attempts: 1,000 at each truth value, with zero worker errors, launch errors, timeouts, interrupted attempts, or nonstarted attempts.
- At slope -0.5, coverage was 968/1,000 = 0.968; its 97.5% Monte Carlo interval was [0.9532, 0.9792], crossing the predeclared upper bound 0.975.
- At slope 0, coverage was 934/1,000 = 0.934; its interval was [0.9142, 0.9505], crossing the lower bound 0.925. The null false-positive rate was 66/1,000 = 0.066; its interval was [0.0495, 0.0858], crossing the upper bound 0.075.
- At slope 0.5, coverage was 950/1,000 = 0.950; its interval [0.9323, 0.9642] was within [0.925, 0.975].
- All 3,000 fits converged with positive Hessians and valid 95% profile intervals. The separate three-case pre-run qualification also passed its integration-oracle checks; it is pipeline evidence, not production calibration evidence.
- The campaign summary reports look2_required and overall_qualified false.
- Source archive SHA-256: 80e3a0314865777bf5343d56b072999f40b7daad07f794bc5347fa7cff8f0af7. Calibration-source archive SHA-256: 84319a4620935d528a9bc84c8a69ffee9538f573d72ec16ccb6c65f31de8320e. Full campaign archive SHA-256: e89d96446c870ba2afb4e75d756601b8045d39b2a7cc9ddfccc7cd22603bebbe. The clean-current look-one manifest SHA-256 is 5e4c567c21cdb3bdabc61119d453563751447fe2fc011faa09f8b795bbdf80cb.
- The focused native test suite previously completed with 564 passes, zero failures, and five Julia-dependent skips because DRM_JL_PATH and DRMODELS_JL_PATH were unset. A separate dirty DRM.jl Bernoulli candidate has documented matched-bridge workflow tests, but this run did not exercise that candidate and it does not establish cross-engine parity or calibration.
- The exact-manifest regression test passed after the fix; the R worker parsed; the profile-level check reported four passing cases.
- This report was checked with the repository after-task validator and prose checker; git diff --check passed.

## 6. Tests of the Tests

The exact-manifest regression test reproduces the prior collision when both manifest.csv and stage-two-manifest.csv are present in the registry, then verifies that basename-exact selection succeeds. The separate pre-run qualification checks the profile pipeline and an independent scalar-cluster Laplace oracle. The production first-look stream uses independent seeds and was summarized from retained attempts. No evidence is inferred from the three-case pre-run.

## 7a. Issue Ledger

- The -0.5 coverage gate is ambiguous.
- The null coverage and false-positive gates are ambiguous.
- The +0.5 coverage gate passes.
- The focused run skipped five live Julia tests because local source paths were unset; a separate dirty DRM.jl candidate and earlier bridge workflow evidence exist, but were not rerun here and do not establish general parity.
- NotebookLM CLI authentication now succeeds for itchyshin@gmail.com. A query of the existing 14-source notebook returned no citation metadata; I treat its gaps as research leads, not evidence. Primary-source verification remains open.
- A later source-bound replay of this same first-look seed stream completed 3,000/3,000 attempts and reproduced look2_required. It reuses already observed seeds, so it provides source-bound reproducibility evidence only.
- A separate historical v8 look-two attempt stopped after 366/3,000 attempts and produced no decision. No completed look-two or calibration qualification claim exists.

## 8. Consistency Audit

This result supersedes the earlier check-log entry stating that no calibration fits or remote compute had run. It does not supersede the staged contract, which still requires a second-look decision for ambiguous gates. The implementation documentation and public support statements remain bounded to the existing Bernoulli slice; this first look does not establish distribution-wide SD support or Julia parity. The separate DRM.jl lane is investigating CMR selection quadrature and has no confirmed source-file overlap with this drmTMB work.

## 9. What Did Not Go Smoothly

The launcher and worker initially matched manifest.csv by suffix, which also selected stage-two-manifest.csv. Two preparation attempts stopped before fitting. Exact-basename matching fixed the issue, and the regression test now protects it. A broad lane preflight stalled during its repository-wide scan, so I stopped only that preflight process and used a narrower status check.

## 10. Known Residuals

This campaign evaluates one univariate Bernoulli random-intercept SD slope design. It does not establish point-estimator recovery, other Bernoulli target types, structured effects, other response families, bivariate models, Julia parity, or general interval calibration. The staged Monte Carlo bands leave three decision rows unresolved. After this report, the same first-look seed stream was replayed under a source-bound v4 install; all 3,000 fits completed and the decision remained look2_required. This audit replay is not an independent calibration. The separate historical v8 look-two attempt was incomplete at 366/3,000 and yielded no decision.

## 11. Team Learning

When an artifact registry contains similarly named manifests, exact basename checks should be covered at both the launcher and worker boundaries. A complete campaign can still be nonqualifying when predeclared uncertainty bands leave gates ambiguous; retain that outcome and its denominators without changing the design after seeing results.

Perceived AI-like style: 2/10, medium confidence. The exact-draft record is `2026-10-19-bernoulli-sd-first-look-calibration.assessment.json`. Scientific and factual gates pass for the report's scoped claims. References are not applicable because this internal report cites no literature.

## 12. Cross-Product Coverage

Covers one current-source native TMB Bernoulli random-intercept SD slope, with three truth values and 3,000 attempted fits, plus pipeline qualification. Does not cover all random-effect types, distribution families, parameter endpoints, structured kernels, bivariate models, Julia parity, point-estimator recovery, or the second-look decision.

## 13. Subsequent source-bound replay readback

On 2026-10-20, the clean-current first-look manifest was replayed under the isolated source-bound v4 installation on Totoro. All 3,000 attempts completed, with 1,000 per slope truth, 3,000 healthy fits, 3,000 valid profile intervals, and no worker errors, launch errors, timeouts, interruptions, or nonstarted attempts. The staged summary again returned `look2_required`; coverage at slopes -0.5 and 0 and the null false-positive gate remained ambiguous, while +0.5 coverage passed. The replay used the already observed master seed 2026101901 and manifest SHA-256 `5e4c567c21cdb3bdabc61119d453563751447fe2fc011faa09f8b795bbdf80cb`, so it provides provenance and reproducibility evidence for the source-bound build only. It adds no independent attempts and does not create a new calibration look. The loaded `drmTMB.so` SHA-256 was `96f128cb0f9802e0a467c012b00ff7659b2ce7ab7a62df41d614bc02a6dbf0fa`; summary and supervisor receipt hashes are recorded in the source-bound evidence README. G2 remains open.
