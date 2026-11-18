# After Task: Julia Binomial animal-intercept SD with covariance A under probit and cloglog

## 1. Goal

Check the animal-intercept random-effect SD route with supplied covariance `A` through both the native TMB and Julia engines under probit and complementary log-log links.

## 2. Implemented

Added a live bridge regression test and linked its exact evidence to the four matching native and Julia capability rows. The model and bridge code already admitted this route, so this slice changed tests and evidence only.

## 3a. Decisions and Rejected Alternatives

The test uses the existing model contract: for group `g`, the Gaussian animal effect has covariance `D A D`, where `D` contains `exp(-0.6 + 0.5 z_g)`. The binary response uses the selected probit or complementary log-log link. Both engines receive the same response data and covariance matrix. Since the candidate already admitted this route, I added a live regression test and left model code and public syntax unchanged.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-animal-A-nonlogit-sd-bridge.R`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-A-nonlogit-bridge-live-20261029/`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-29-julia-binomial-animal-A-nonlogit-bridge.md`
- This report.

## 5. Checks Run

The focused test passed with one live Julia bridge test for both links. Each link fit one TMB model and one Julia model. The test checks convergence, slope recovery within 0.55 of the generating value, TMB-to-Julia slope agreement within 0.35, log-likelihood agreement within 0.02, and fitted group-SD agreement within 0.03.

The evidence reconciler passed with 20,350 candidate rows, 208 evidence records, 188 linked rows, and 20,162 unlinked rows. The source manifest verified all nine listed hashes. The after-task structure, closeout, and slop checks passed. Closeout reports 13 acceptance ledgers as not runnable, so their gate state remains UNKNOWN. The focused R-to-Julia phylogenetic Binomial filter also passed earlier in this session, with three live tests for logit, probit, and cloglog; its existing source-bound receipt remains unchanged.

## 6. Tests of the Tests

The fixed seeds make the group-level SD predictor, latent field, and responses for each link reproducible. Both engines receive the same simulated data and `A`, which has unequal diagonal entries. The fitted coefficients, likelihoods, and predicted animal SDs are compared, so the test exercises the bridge and model fit rather than only a route-admission helper.

## 7a. Issue Ledger

`gh issue list --state open --search 'Binomial animal SD covariance A probit cloglog' --limit 10` returned no matching issue. No issue was opened or changed.

## 8. Consistency Audit

The response remains Bernoulli with no free residual `sigma`; the predictor-dependent SD is on the latent link scale. This receipt covers one q1 animal intercept, covariance input `A`, and two links. It does not extend the public formula grammar. Existing model documentation already describes `sd(group)` and structured effects, so this evidence-only change does not update formula guides, NEWS, roadmap, known limitations, or pkgdown navigation.

## 9. What Did Not Go Smoothly

The shared lane registry was slow to grant the scoped lease. I stopped my stalled helper processes, retried once, and received the lease before editing.

## 10. Known Residuals

This test is focused point and workflow evidence. It is not an interval-coverage study and does not establish general animal, random-effect, family, or Julia parity. The four evidence rows remain unreviewed, and the broader programme remains incomplete. Next, continue with the next uncovered Bernoulli provider or effect row after checking both engines' current base support. Keep interval coverage deferred.

## 11. Team Learning

Keep evidence linked to the exact engine, link, provider, and covariance input. The existing route was already implemented; the missing piece here was a live test and exact evidence for the probit and cloglog `A` cells.

## 12. Cross-Product Coverage

Covers current R-to-TMB and R-to-Julia candidate fits for a Bernoulli animal-intercept SD regression with supplied covariance `A` under probit and cloglog. It does NOT cover interval calibration, other animal inputs, other providers, or release readiness.

Prose assessment: `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-A-nonlogit-bridge-live-20261029/after-task-assessment.json`.

Memory receipt: Read `memory/00-INDEX.md`; `route.py` found no LOAD-FIRST manifest. The carried project evidence notes reinforced exact-row receipts and no status promotion, which I applied here. Golden Set: not run; this test-and-evidence slice does not address a known-mistake class.
