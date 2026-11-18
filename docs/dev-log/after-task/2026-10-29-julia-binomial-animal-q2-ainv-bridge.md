# After Task: Julia Binomial animal q2 Ainv bridge evidence

## 1. Goal

Check whether the current Julia bridge fits the Binomial animal intercept-plus-slope SD model when the user supplies an animal precision matrix, `Ainv`.

## 2. Implemented

Added a focused live bridge regression test. It verifies exact `Ainv` payload forwarding, native-versus-Julia fit and predicted SD agreement, and a seeded Julia marginal draw against an independently assembled draw using the equivalent covariance matrix. The existing code passed, so this slice changed no model or bridge implementation.

## 3a. Decisions and Rejected Alternatives

Keep this as a regression test and evidence update. The direct Julia route and R bridge already handled the supplied `Ainv` input. Do not claim pedigree parity from this covariance-matrix test.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-animal-q2-sd-ainv.R`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-q2-ainv-bridge-live-20261029/receipt.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-q2-ainv-bridge-live-20261029/source-manifest.sha256`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-q2-ainv-bridge-live-20261029/test-console.log`
- `docs/dev-log/check-log.md`, this report, and `docs/dev-log/check-log.d/2026-10-29-julia-binomial-animal-q2-ainv-bridge.md`.

## 5. Checks Run

On drmTMB candidate `425bee81572c625a634b2b083050c5c57c1dc1f1` and DRM.jl candidate `70dbf564eb670144c63c08f61ea099084d95add2`, the focused command in the receipt passed. Three live Julia bridge tests ran. The new fixture checks the logit q2 model with 80 groups and 24 observations per group. The run log, source hashes, and receipt are retained under `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-q2-ainv-bridge-live-20261029/`.

The new test confirms that the payload uses keyword `Ainv` and exactly matches the supplied precision matrix. Fitted likelihood, coefficients, and group SD predictions agree with native TMB at the declared test tolerances. The Julia simulator returned binary draws identical to the seeded independent covariance-based draw.

The evidence reconciler passed with 198 evidence records, 178 distinct linked rows, and 20,172 unlinked rows of 20,350 candidates. This updates evidence linkage only; it does not promote capability status. The source manifest verified against all listed source and log files, and scoped `git diff --check` passed.

## 6. Tests of the Tests

The seeded simulation assertion independently builds the correlated intercept and slope fields from `A`, then applies the fitted coefficient-specific group SDs and observation-level slope covariate. This distinguishes correct `Ainv` bridge plumbing from a fit-only success.

## 7a. Issue Ledger

No issue was opened or changed. The broad test-sweep issue does not track this specific input route.

## 8. Consistency Audit

The formula still contains one animal intercept-plus-slope block with two separate SD formulas and a constant coefficient correlation. The response is Bernoulli with no residual `sigma`. The evidence ledger links only the two Julia logit q2 coefficient rows with animal `Ainv_precision`; no capability status was promoted.

## 9. What Did Not Go Smoothly

The lane lease registry responded slowly while its shared lock was busy. The scoped lease was confirmed before writing the receipt and evidence records. The first unlogged test pass established the result; a second focused pass retained the source-bound console log.

## 10. Known Residuals

This check covers one complete-data synthetic logit fixture, one supplied `Ainv` animal q2 block, fit/output agreement, and marginal simulation. It does not establish probit or cloglog `Ainv` parity, pedigree bridge parity, repeated-sample recovery, interval calibration, coverage, or broad Julia parity. The required capability rows remain unresolved pending review and additional gates.

## 11. Team Learning

When the direct engine already supports a structured input that the bridge appears to pass generically, add a live fixture before changing admission logic. This found an evidence gap rather than an implementation bug.

Memory receipt: project route lookup found no LOAD-FIRST manifest, and `graft` is unavailable in this environment. I used the exact source and test locations. Golden Set: not run; this input-route regression test sits outside the registered repeated-mistake classes.

The after-task structure checker passed. It reports the larger 13-file acceptance ledger as UNKNOWN because its configured gate runner is missing. The prose style checker reported zero findings.

## 12. Cross-Product Coverage

Covers the current R-to-Julia candidate bridge for Binomial logit animal q2 with supplied `Ainv`, including native comparison, coefficient-specific SD predictions, and seeded marginal simulation.

Does not cover pedigree, other structured inputs, other links for this q2 input, additional random-effect types, interval coverage, all response families, full package checks, or release readiness.

## 13. Next Actions

Continue with the next unverified Bernoulli animal input route, likely pedigree, after checking current candidate rows and preserving the same source-bound evidence standard. Keep interval coverage deferred.
