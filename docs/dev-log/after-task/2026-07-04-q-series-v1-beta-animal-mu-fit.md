# After Task: Q-Series v1 Beta Animal Mu Local Fit-Only Recovery

## 1. Goal

Move the narrow `beta()` `mu` animal intercept row from expected rejection to
local fit-only recovery for the v1.0 basic-distribution surface, without
opening interval, coverage, bridge, q2/q4, REML, AI-REML, `supported`, or
public-support claims.

## 2. Implemented

`drm_build_beta_ls_spec()` now accepts exactly one structured `mu` route:
`animal(1 | id, pedigree = ped)` or its existing known-covariance equivalent.
The beta builder reuses the structured known-covariance path, adds the
structured latent effect to beta `eta_mu`, and reports the direct animal
structured SD through the existing extractor surface.

The first-four smoke is now a gate smoke rather than a pure rejection smoke:
`qseries_beta_mu_animal_rejected` is expected to fit locally, while
`qseries_gamma_mu_relmat_rejected`, `qseries_ordinal_mu_phylo_rejected`, and
`qseries_student_mu_spatial_rejected` remain expected pre-optimization
rejections.

## 3a. Decisions and Rejected Alternatives

Decisions:

- Admit only the beta `mu` animal intercept route as local fit-only recovery.
- Keep Gamma relmat, ordinal phylo, and Student spatial as expected
  pre-optimization rejections.
- Rename the smoke output column from `rejection_id` to `gate_id` so the beta
  fit row is not labelled as a rejection.
- Rotate the active first-candidate artifacts to generic filenames because the
  beta-specific design/debug fixture files are now historical July 3 artifacts.

Rejected alternatives:

- Do not treat the beta animal fit as a retained denominator.
- Do not move beta animal to `inference_ready` or `supported`.
- Do not broaden the route to beta scale random effects, beta slopes,
  zero-one beta, q2/q4, bridge, REML, AI-REML, or public support.

## 3b. Mathematical Contract

The admitted local fit-only route is:

```text
y_i ~ beta(mu_i, phi)
logit(mu_i) = X_i beta + u_id[i]
u ~ N(0, sigma_animal^2 A)
```

This is a direct point-fit route only. It does not establish retained
denominators, Wald/profile intervals, coverage, `inference_ready`, `supported`,
REML, AI-REML, q2/q4 behavior, bridge behavior, beta scale random effects,
structured beta slopes, or zero-one beta support.

## 4. Files Touched

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tools/qseries-v1-first-four-rejection-smoke.R`
- `tools/qseries_v1_release_check.py`
- `tools/qseries_v1_claim_guard.py`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-structured-family-rejection-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-v1-readiness-reset.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/release-audits/q-series-v1-release-status.md`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `docs/dev-log/release-audits/q-series-v1-next-candidate-review.tsv`
- `docs/dev-log/release-audits/q-series-v1-75pct-review-packet.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-candidate-design-contract.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-candidate-debug-fixture-contract.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-four-design-contracts.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-four-debug-fixture-contracts.tsv`
- `tests/testthat/test-nongaussian-structured-boundary.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py`
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "pkgbuild::compile_dll(debug = FALSE, quiet = TRUE); cat('compile_dll_ok\n')"`
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file tools/qseries-v1-first-four-rejection-smoke.R`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
- `python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'nongaussian-structured-boundary', reporter = 'summary')"`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'structured-re-conversion-contracts', reporter = 'summary')"`
- `git diff --check`
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-07-04-q-series-v1-beta-animal-mu-fit.md')"`

## 6. Tests of the Tests

The conversion-contract test failed once because it still expected 18
non-Gaussian rejected audit rows. After the beta animal row moved to
`non_gaussian_point_only`, the correct state counts are 18 recovery-only,
0 caveat, 17 rejected, 1 planned, and 1 point-only.

## 7a. Issue Ledger

No GitHub issue was opened or commented on. This was local v1.0 Q-Series
implementation, dashboard, and validation work on the active branch.

## 8. Consistency Audit

Rose boundary: this slice changes one local fit-only support cell and no
interval/coverage/support status. The Q-Series board still has 104 support
cells, 8 exact `inference_ready` anchors, 0 `supported` authority rows, and no
q4/q8 or non-Gaussian interval/coverage promotion.

Fisher boundary: the beta animal smoke is not a retained denominator. It is a
single deterministic local fit check with no coverage, profile, Wald, MCSE, or
admission interpretation.

Grace boundary: Mission Control and the generated v1 release checker both pass
after regenerating the release ledger, release status, preflight report, and
candidate-review artifacts.

## 9. What Did Not Go Smoothly

The first conversion-contract rerun caught one stale dashboard expectation: it
still expected 18 non-Gaussian rejected audit rows. The corrected count is 17
rejected plus one `non_gaussian_point_only` beta animal row.

## 10. Known Residuals

The row remains local fit-only recovery evidence. It is not interval-ready,
coverage-ready, `inference_ready`, `supported`, bridge-supported, q2/q4,
REML/AI-REML, or public support. The next first-four review packet now starts
with Gamma `mu` relmat, ordinal `mu` phylo, Student `mu` spatial, and beta
`sigma` animal, all still design-only.

## 11. Team Learning

When a row moves from expected rejection to local fit-only recovery, update the
machine-readable identifier language too. The `gate_id` rename prevented a
successful beta fit from carrying a stale `rejection_id` label.

## 12. Next Actions

If the v1.0 campaign needs three more rows to reach the 75% row-accounting
target, review the new first-four packet before any further implementation.
Keep the same rule: cheapest local fit-only evidence first, and no interval or
coverage claims without a separate retained-denominator design and
Rose/Fisher/Grace review.
