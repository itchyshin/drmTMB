# After Task: bivariate sd_phylo1/2 REML ceiling regression test (#17)

Meta: 2026-07-08 · Claude (Opus 4.8) · repo `drmTMB` · branch
`drmtmb/fix-16-phylo-mu-diagnostics` off `main` `bed29701`.

## 1. Goal

Lock in the `se_group_sd` ceiling fix (A. Mizuno issue #3) with a CI regression test for
the *bivariate* `sd_phylo1/2` REML case, so the ceiling cannot silently return.

## 2. Implemented

- New test in `tests/testthat/test-control.R`: a bivariate direct-SD phylo model
  (`sd_phylo1(species) ~ z_species`, `sd_phylo2(species) ~ z_species`) fit under REML at a
  16-tip balanced tree. Asserts, with the default `se_group_sd = FALSE`: REML estimator;
  the per-group `sd_phylo_group` ADREPORT stays OUT of `sdreport`; `nrow(fit$sdr$cov)` is
  small (< 2 * n_tip, i.e. not n_group x n_group); finite `vcov()` and `summary()` SEs;
  `pdHess = TRUE`.

## 3a. Decisions and Rejected Alternatives

- **Synthetic fixture, not Ayumi's data.** Her real 10,440-tip data/tree is not in the
  repo (only her analysis scripts under `tools/`), and 10,440 tips cannot run in CI. The
  ceiling mechanism (keeping the direct-SD ADREPORT out of the joint covariance) is
  scale-invariant, so a 16-tip synthetic proxy locks in the behaviour at CI speed; the fix
  was already validated at her full scale separately (issue #3 close-out).
- **Placed in `test-control.R`** beside the univariate `se_group_sd` test, reusing
  `control_balanced_ultrametric_tree()`; the univariate test already covers the on/off
  ADREPORT-size contrast, so #17 focuses on the bivariate default-FALSE finite-SE guarantee.

## 4. Files Touched

- `tests/testthat/test-control.R` — new test.
- `docs/dev-log/after-task/2026-07-08-issue17-biv-reml-ceiling-regression.md` — this note.

## 5. Checks Run

- `test-control.R` → FAIL 0 | PASS 156 (+8 from the new test).
- Prototype (`scratchpad/proto_17.R`) confirmed every assertion before finalizing:
  `nrow(sdr$cov)=13 < 32`, finite SEs, `pdHess=TRUE`, `conv=0`.

## 6. Tests of the Tests

- The assertion `nrow(fit$sdr$cov) < 2 * n_tip` would fail if the direct-SD ADREPORT ever
  re-entered `sdreport` by default (the exact regression the ceiling fix prevents).
- The default `se_group_sd == FALSE` is asserted directly, so a change of default trips it.

## 7a. Issue Ledger

- Closes #17. No new issues.

## 8. Consistency Audit

- Mirrors the existing univariate `se_group_sd` REML test's assertion pattern
  (`nrow(sdr$cov) < 2*n_tip`, finite SEs), keeping the two ceiling regressions consistent.

## 9. What Did Not Go Smoothly

- Nothing of note; the prototype passed on the first configuration.

## 10. Known Residuals

- The fixture is 16 tips; it proves the mechanism, not full-scale performance. Full-scale
  behaviour is Ayumi's live confirmation (issue #3), not a CI concern.

## 11. Team Learning

- A scale-invariant mechanism (ADREPORT membership) can be regression-tested at CI scale
  even when the reported failure was at 10,440 tips — assert the *mechanism* (covariance
  dimension), not the symptom (wall-clock / memory).

## 12. Cross-Product Coverage

- **covers ✓**: bivariate `sd_phylo1/2` under REML with the default `se_group_sd`, asserting
  the ADREPORT stays out, the covariance stays small, and SEs/`pdHess` are finite.
- **does NOT cover ✗**: full-scale (10,440-tip) performance; the `se_group_sd = TRUE` opt-in
  path (covered by the univariate test); non-REML/ML biv direct-SD (covered by
  `test-check-drm.R`); the location-scale-scale combination (C2, still unbuilt).
