# After Task: Julia Binomial animal-slope SD with covariance A under probit and cloglog

## 1. Goal

Check predictor-dependent SDs for a structured animal slope using supplied covariance `A` through native TMB and Julia under probit and complementary log-log links.

## 2. Implemented

Added a live regression test and linked its exact source-bound evidence to the four matching native and Julia required rows. The candidate already admitted this model route, so the slice changed tests and evidence only.

## 3a. Decisions and Rejected Alternatives

The test uses `animal(0 + x | id, A = A)` and `sd(id, level = "animal") ~ z`. For group `g`, its slope coefficient has SD `exp(-0.45 + 0.55 z_g)` and covariance `D A D`. I did not add a separate formula interface or change route admission because both engines already accept the tested route.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-animal-slope-A-nonlogit-sd-bridge.R`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-slope-A-nonlogit-bridge-live-20261029/`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-29-julia-binomial-animal-slope-A-nonlogit-bridge.md`
- This report.

## 5. Checks Run

The focused test passed with one live Julia bridge test covering both links. Each link fit one TMB model and one Julia model. Both engines converged; each estimated the log-SD slope within 0.65 of truth, agreed within 0.4, matched log likelihood within 0.05, and returned fitted group SDs within 0.04.

The evidence reconciler passed with 20,350 candidate rows, 212 evidence records, 192 linked rows, and 20,158 unlinked rows. The source manifest verified all nine hashes. Report structure, closeout, and slop checks passed. The closeout tool reports 13 acceptance ledgers as not runnable, so their state remains UNKNOWN.

## 6. Tests of the Tests

Fixed seeds determine the group SD predictor, latent animal slope, and responses under each link. The slope covariate varies within group, while its SD predictor is constant within group. Both engines receive the same data and the same covariance matrix. The test compares recovery, fitted likelihoods, and SD outputs. It does not compare against an independent likelihood oracle.

## 7a. Issue Ledger

`gh issue list --state open --search 'Binomial animal slope SD covariance A probit cloglog' --limit 10` returned no matching issue. No issue was opened or changed.

## 8. Consistency Audit

The response is Bernoulli with no free residual `sigma`; the predictor-dependent SD is on the link scale. This slice covers one q1 animal slope, covariance input `A`, and two links. The formula grammar and model implementation were already present, so no public documentation, NEWS, roadmap, known-limitations, or pkgdown changes were needed.

## 9. What Did Not Go Smoothly

The lane preflight took several minutes to finish its background scan. Its scoped result showed no conflicting path edits, and the lease was granted before the new test was added.

## 10. Known Residuals

This is focused point-recovery and output agreement evidence. It is not interval calibration or coverage evidence, and it does not establish support for other animal inputs, other providers, other random-effect structures, or other families. The four evidence rows remain unreviewed. Continue with the next uncovered Bernoulli row; keep interval coverage deferred.

## 11. Team Learning

For a structured random slope, verify that the SD predictor is constant within group while the slope covariate varies within group. Keep those two roles distinct in the fixture and in its evidence description.

## 12. Cross-Product Coverage

Covers current R-to-TMB and R-to-Julia fits for a Bernoulli animal slope with supplied covariance `A` under probit and cloglog. It does NOT cover interval calibration, other animal inputs, other random-effect types, or release readiness.

Prose assessment: `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-slope-A-nonlogit-bridge-live-20261029/after-task-assessment.json`.

Memory receipt: Read `memory/00-INDEX.md`; `route.py` found no LOAD-FIRST manifest. The saved SD-regression guidance to select an exact uncovered row and keep evidence claims narrow shaped this slice. Golden Set: not run; this test-and-evidence slice does not address a known-mistake class.
