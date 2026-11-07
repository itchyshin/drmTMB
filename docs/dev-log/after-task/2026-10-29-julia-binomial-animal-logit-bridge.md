# After Task: Julia Binomial animal-intercept logit with A and Ainv

## 1. Goal

Add current source-bound evidence for the Julia Bernoulli logit animal-intercept SD route with supplied covariance `A` and precision `Ainv`.

## 2. Implemented

Reran the existing live cross-engine fixture and linked the two Julia q1 target rows. Native rows were already linked by earlier evidence. No model or test source changed in this slice.

## 3a. Decisions and Rejected Alternatives

Keep the existing route and test unchanged. The current test covers both relationship-matrix representations, and its exact source and log are now linked to the required Julia rows.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-logit-bridge-live-20261029/receipt.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-logit-bridge-live-20261029/source-manifest.sha256`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-logit-bridge-live-20261029/test-console.log`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-29-julia-binomial-animal-logit-bridge.md`
- This report.

## 5. Checks Run

On drmTMB candidate `425bee81572c625a634b2b083050c5c57c1dc1f1` and DRM.jl candidate `70dbf564eb670144c63c08f61ea099084d95add2`, the focused `julia-binomial-animal-sd-regression` test filter passed with two live Julia bridge tests.

The animal-intercept fixture fits supplied `A` and `Ainv` using the same synthetic response. Native and Julia fits recover the generating log-SD slope within test tolerance, agree on the slope and likelihood, and return matching group SDs. Within each engine, the `A` and `Ainv` fits agree.

The evidence reconciler passed with 20,350 candidate rows, 204 receipt records, 184 linked rows, and 20,166 unlinked rows. It links the Julia logit animal-intercept rows for `A_covariance` and `Ainv_precision`. No capability status was promoted. The source manifest verifies the exact source, test, and log hashes.

## 6. Tests of the Tests

The existing fixture generates one latent animal field from a known covariance, computes `Ainv` from that same matrix, and fits both representations against the same responses. The cross-engine and covariance-versus-precision checks make the evidence specific to input handling and fitted output.

## 7a. Issue Ledger

No route-specific issue was found or changed.

## 8. Consistency Audit

The fitted model uses a Bernoulli animal q1 random intercept with one fixed-effect SD formula and no residual `sigma`. The Julia evidence covers logit only and the two supplied matrix representations. Earlier native receipts already cover the corresponding native rows. Probit/cloglog, pedigree, q2, and interval calibration remain separate.

## 9. What Did Not Go Smoothly

The first evidence-reconciliation pass for the preceding slice exposed how a changed test path can invalidate earlier source-bound records. The earlier test file remained byte-identical in this slice, and the new receipt uses that exact test path and current hash.

## 10. Known Residuals

This is one synthetic q1 logit fixture. It does not establish other links, animal pedigree, animal q2, other providers, interval calibration, coverage, broad Julia parity, or release readiness. The two Julia rows remain unreviewed and unresolved pending broader gates.

## 11. Team Learning

When a current test already exercises multiple matrix inputs, reuse that test and link its exact evidence before adding duplicate fixtures.

Memory receipt: project route lookup found no LOAD-FIRST manifest, and `graft` is unavailable in this environment. I used the exact source and test locations. Golden Set: not run; this evidence-link update sits outside the registered repeated-mistake classes.

## 12. Cross-Product Coverage

Covers current R-to-TMB and R-to-Julia candidate fits for Bernoulli logit animal-intercept SD regression with supplied `A` and `Ainv`, including coefficient recovery and fitted SD outputs.

Does not cover other links, pedigree, q2, other providers, interval calibration, coverage, full package checks, or release readiness.

## 13. Next Actions

Continue with the next uncovered Bernoulli provider/input row after checking current base-engine support. Keep interval coverage deferred.
