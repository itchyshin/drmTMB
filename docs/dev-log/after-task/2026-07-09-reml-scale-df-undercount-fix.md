# After Task: fix REML df/AIC under-count for scale-side fits (`drm_fit_df`)

Meta: 2026-07-09 · Claude (Opus 4.8) · repo `drmTMB` · branch `drmtmb/fix-reml-scale-df`
off `main` `bed29701`. Pre-existing bug found by Noether during the C1 review (task_befac4a1).

## 1. Goal

Under REML, TMB marginalizes the mean fixed effects (`beta_mu`) into the Laplace `random`
block, and `drm_fit_df` added `ncol(X$mu)` back to `df` to count them. But when a sigma
variance component is present, `drm_apply_estimator_spec` ALSO marginalizes `beta_sigma`
(gated on `has_sigma_re`), and `drm_fit_df` never added `ncol(X$sigma)` back — so `df`, and
hence AIC/BIC via `logLik()`'s `df` attribute, under-counted the scale fixed effects for
every scale-side REML fit (ordinary scale RE, phylo scale, and the new C1 non-phylo scale).
Fix it; count the scale fixed effects too.

## 2. Implemented

- `drm_fit_df` (`R/drmTMB.R`) now adds back a marginalized fixed-effect block's columns iff
  that block is present in `spec$tmb_random_names` — the actual record of what was
  marginalized. Univariate: `beta_mu`→`X$mu`, `beta_sigma`→`X$sigma`. Bivariate: the four
  `beta_{mu,sigma}{1,2}` → the matching `X` blocks. Reading `tmb_random_names` (rather than
  re-deriving the `has_sigma_re` gate) keeps `df` in lockstep with the marginalization and
  cannot drift from it — the root failure mode here was exactly such a drift.
- New regression test in `tests/testthat/test-reml-heteroscedastic.R`: a `sigma ~ x + (1|id)`
  REML fit has `beta_sigma` marginalized, so `df == length(opt$par) + ncol(X$mu) + ncol(X$sigma)`,
  and REML df == ML df for the same model.

## 3a. Decisions and Rejected Alternatives

- **Source of truth = `tmb_random_names`, not a re-derived `has_sigma_re`.** Re-deriving the
  gate would duplicate `drm_apply_estimator_spec`'s logic and could silently drift out of
  sync (the very way this bug arose). `tmb_random_names` is what TMB actually marginalized.
- **REML df := total model parameter count (== ML df).** The fix makes REML df equal the ML
  df for the same model. This is the intended convention (the existing mean-side add-back
  already implied it) and the right basis for AIC/BIC; drmTMB additionally warns that REML
  AIC is only comparable across identical fixed effects.
- **No roxygen change.** `logLik()`'s doc already calls `df` the "top-level parameter count";
  the fix makes it accurate, not contradicted.

## 4. Files Touched

- `R/drmTMB.R` — `drm_fit_df`.
- `tests/testthat/test-reml-heteroscedastic.R` — new regression test.
- `docs/dev-log/after-task/2026-07-09-reml-scale-df-undercount-fix.md` — this note.

## 5. Checks Run

- Empirical before/after: `sigma ~ x + (1|id)` REML df 3 → 5 (== ML df 5); `sigma ~ x`
  (no sigma RE) df unchanged at 5 (`beta_sigma` stays in `opt$par`, not in `tmb_random_names`).
- df-adjacent files green: `test-reml-heteroscedastic` (9), `test-reml-bivariate` (27),
  `test-reml-ordinary-sigma` (17), `test-comparators` (96), `test-information-criterion-guard` (16).
- Full `devtools::test()` → FAIL 0 | PASS 36,641 after the conformance-TSV citation
  update below (the `drm_fit_df` edit shifted `R/drmTMB.R` line numbers, so the
  `reml_gate_sd_phylo_plus_sigma_phylo` evidence citation drifted 10546 → 10561 and
  `test-estimator-surface-conformance.R` flagged it — the documented line-drift gotcha).

## 6. Tests of the Tests

- The new test asserts the exact corrected df (`+ ncol(X$mu) + ncol(X$sigma)`) AND the
  estimator-invariance (REML df == ML df) — either would fail on the pre-fix under-count.
- The pre-existing mean-only df tests (`test-reml-heteroscedastic:81`, `test-reml-bivariate:76,89`)
  all use scale FIXED effects (no sigma RE), so `beta_sigma` is not marginalized and their
  `+2L`/`+4L` assertions correctly stay unchanged — verified green.

## 7a. Issue Ledger

- Closes task_befac4a1. No new issues.

## 8. Consistency Audit

- Verified the only `df` consumers are `logLik.drmTMB` (→ `AIC`/`BIC`/`deviance`/`df.residual`);
  no code relied on the under-counting. The three existing df assertions are all no-sigma-RE
  cases and are unaffected.

## 9. What Did Not Go Smoothly

- The `drm_fit_df` edit shifted `R/drmTMB.R` line numbers, drifting one conformance-TSV
  evidence citation (`R/drmTMB.R:10546` → `10561`) — the exact line-drift gotcha the C1
  handover flagged. Caught by `test-estimator-surface-conformance.R`; TSV updated.

## 4a. Files Touched (addendum)

- `docs/dev-log/dashboard/estimator-surface-conformance.tsv` — one evidence-line citation
  updated for the line shift.

## 10. Known Residuals

- REML AIC/BIC remain estimator-comparable only across identical fixed effects (drmTMB
  already warns this); the fix corrects the parameter count, not that comparability caveat.

## 11. Team Learning

- When two functions must agree on a derived quantity (here: which fixed effects are
  marginalized), have the second READ the first's recorded output (`tmb_random_names`)
  rather than recompute the gate. Recomputation is how the mean/scale halves drifted apart.

## 12. Cross-Product Coverage

- **covers ✓**: univariate and bivariate REML df/AIC for fits that marginalize `beta_sigma`
  (any sigma variance component: ordinary scale RE, phylo scale, C1 non-phylo scale).
- **does NOT cover ✗**: no change to the likelihood value, to ML df, to no-sigma-RE REML df,
  or to the REML-AIC comparability caveat; not a new estimator or family.
