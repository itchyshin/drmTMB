# After Task: Julia Binomial animal-intercept Ainv under probit and cloglog

## 1. Goal

Verify the Julia bridge's Bernoulli animal-intercept SD route with supplied `Ainv` under probit and complementary log-log links.

## 2. Implemented

Made the group-level SD-predictor assignment deterministic in the existing synthetic test and reran its live TMB and Julia fits. Both links passed. No model or bridge source changed.

## 3a. Decisions and Rejected Alternatives

Preserve the exact q1 route and existing link admission. The useful change here is a stable synthetic assignment and current source-bound evidence, not wider model admission.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-animal-ainv-nonlogit-sd-bridge.R`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-ainv-nonlogit-bridge-live-20261029/receipt.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-ainv-nonlogit-bridge-live-20261029/source-manifest.sha256`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-ainv-nonlogit-bridge-live-20261029/test-console.log`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-29-julia-binomial-animal-ainv-nonlogit-bridge.md`
- This report.

## 5. Checks Run

On drmTMB candidate `425bee81572c625a634b2b083050c5c57c1dc1f1` and DRM.jl candidate `70dbf564eb670144c63c08f61ea099084d95add2`, the focused test passed with one live Julia bridge test covering both links. The source-bound command and output are in the evidence receipt.

For each link, the test verifies convergence, log-SD slope recovery against the synthetic truth, TMB-versus-Julia slope and likelihood agreement, and predicted animal SD agreement. The fixture uses 80 groups, 32 observations per group, a non-unit-diagonal relationship matrix, and a fixed seed for assigning group-level SD predictors.

The evidence reconciler passed with 20,350 candidate rows, 202 receipt records, 182 linked rows, and 20,168 unlinked rows. It links the native and Julia q1 animal-intercept `Ainv_precision` rows for probit and cloglog. The source manifest verifies the exact source, test, and log hashes. No capability status was promoted.

## 6. Tests of the Tests

The simulated animal effects use the same non-unit-diagonal covariance whose inverse is passed to both engines. Group-level SD predictors are assigned from a fixed seed and are independent of the covariance ordering. The two links share the same generated latent effects while responses use link-specific seeds.

## 7a. Issue Ledger

No route-specific issue was found or changed.

## 8. Consistency Audit

The fit remains a Bernoulli animal random intercept with a group-constant predictor on its SD and no residual `sigma`. Evidence includes native and Julia fits for the two tested links and one supplied `Ainv` route. The separate logit, q2, pedigree, and other-provider routes are unaffected.

## 9. What Did Not Go Smoothly

The earlier fixture sampled the group-level SD predictor before setting its seed. I added a fixed seed at that assignment point, retained the separate seeds for latent effects and responses, and reran the live bridge test.

## 10. Known Residuals

This evidence covers one synthetic q1 route with supplied `Ainv` under probit and cloglog. It does not establish interval calibration, coverage, pedigree parity, animal q2, every link or provider, or broad family support. The four evidence rows remain unreviewed and required programme gates remain open.

## 11. Team Learning

Set the seed before every random fixture assignment, including group-level predictor layouts. A later seed does not make earlier sampling reproducible.

Memory receipt: project route lookup found no LOAD-FIRST manifest, and `graft` is unavailable in this environment. I used the exact source and test locations. Golden Set: not run; this deterministic-fixture correction sits outside the registered repeated-mistake classes.

## 12. Cross-Product Coverage

Covers current R-to-TMB and R-to-Julia candidate fits for Bernoulli animal-intercept SD regression with supplied `Ainv` under probit and cloglog, including synthetic slope recovery, likelihood agreement, and predicted SD agreement.

Does not cover logit for this test fixture, animal q2, pedigree, other providers, interval calibration, coverage, full package checks, or release readiness.

## 13. Next Actions

Continue with an uncovered Bernoulli provider/input row after checking its base-engine support and current exact source. Keep interval coverage deferred.
