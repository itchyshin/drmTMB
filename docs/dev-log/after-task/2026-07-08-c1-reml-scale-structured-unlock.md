# After Task: C1 — REML unlock for scale-side spatial/animal/relmat structured effects

Meta: 2026-07-08 (night) · Claude (Opus 4.8) · repo `drmTMB` · branch
`drmtmb/c1-reml-scale-structured` off `main` `bed29701`. Evidence campaigns on Totoro.

## 1. Goal

Relax the REML provider gate so scale-side (`sigma ~ ...`) spatial / animal / relatedness
structured effects fit under REML, gated on recovery-to-truth + interval coverage evidence
(not a single small-g cell). R-side only; the fit mechanism already worked (the recovery
ladder fit these via a namespace bypass).

## 2. Implemented

- `drm_validate_reml_spec` (univariate Gaussian path, `R/drmTMB.R`): a non-phylo structured
  effect is now admitted under REML iff every endpoint targets the scale (sigma) —
  `scale_side_only <- length(phylo_mu_dpar_codes(phylo_mu)) > 0L && all(phylo_mu_dpar_codes(phylo_mu) == 1L)`.
  Mean-side (code 0) and mean+scale-spanning (codes 0 and 1) non-phylo effects stay
  rejected, with a sharpened message. The bivariate path is unchanged (no biv evidence).
- New `tests/testthat/test-reml-scale-structured.R`: scale-side spatial/animal/relmat
  (and intercept-only) fit + recover under REML; mean-side and mean+scale-spanning stay
  rejected.

## 2a. Evidence campaigns (Totoro, 64 cores)

Both drivers + logs archived under
`docs/dev-log/simulation-artifacts/2026-07-08-c1-reml-provider-unlock/`.

- **Recovery, N=400 seeds** (`reml_provider_ladder_parallel.R`), target = scale-side
  intercept SD (truth 0.50), g-ladder 8/16/32 (animal g=8, fixed pedigree):
  REML debiases the intercept SD **400/400 in every cell**; REML bias ≈ 0 (spatial
  −0.009/−0.011/−0.019; relmat −0.020/−0.017/−0.004; animal −0.017) while ML bias is
  3–7× larger and shrinks with g — a consistent, small-sample-biased estimator. Slope-SD
  REML<ML reversal is the documented non-bug (no fixed `x` for the slope) and shrinks
  with g. Convergence 400/400 both estimators.
- **Coverage, N=300 seeds** (`c1_coverage_driver.R`), REML profile-CI coverage of the
  intercept SD: every cell clears the g=8 `inference_ready` floor of 0.91 —
  spatial 0.969/0.926/0.947, relmat 0.983/0.926/0.927, animal 0.974 (MCSE ≈ 0.01–0.015).
  Finite-CI rate 85–100%, improving with g (the expected small-g profile-boundary caveat).

Verdict: recovery sound + coverage `inference_ready` → admit the fit. **`supported` NOT
claimed** (deferred tier); the 8 existing `inference_ready` cells were not touched.

## 3a. Decisions and Rejected Alternatives

- **Scale-side only, univariate only.** The evidence is univariate `sigma ~ provider(...)`.
  Mean-side provider REML and the bivariate path have no evidence, so both stay rejected —
  evidence-bounded relaxation, not a blanket unlock.
- **No C++/constructor/DATA_* change.** The gate was the only barrier; the fit mechanism
  (beta_sigma marginalization) already handles K-based scale variance components. So the
  `test-phylo-utils.R` DATA_INTEGER lesson did not apply.
- **Did not fix the `drm_fit_df` scale-side df under-count** found in review — see §10.

## 4. Files Touched

- `R/drmTMB.R` — gate relaxation + comment.
- `tests/testthat/test-reml-scale-structured.R` — new.
- `docs/dev-log/simulation-artifacts/2026-07-08-c1-reml-provider-unlock/` — drivers + logs.
- `docs/dev-log/after-task/2026-07-08-c1-reml-scale-structured-unlock.md` — this note.

## 5. Checks Run

- `test-reml-scale-structured.R` → FAIL 0 | PASS 13.
- Full `devtools::test()` → (recorded in §5a on completion).
- Local verification: scale-side spatial/relmat/animal (1+x|id) and intercept-only fit
  under REML (conv 0); mean-side spatial/relmat still rejected.

## 5a. Full-suite result

- (TOTAL FAIL / PASS pasted on completion.)

## 6. Tests of the Tests

- The bounded-relaxation test asserts the exact new rejection message
  ("Mean-side spatial, animal, and relatedness"), so a future over-broad relaxation trips it.
- The admission test asserts `estimator == "REML"`, `conv == 0`, and a finite positive
  fitted intercept SD per provider.

## 7a. Issue Ledger

- C1 implemented (univariate scale-side). Follow-ups: biv C1 (no evidence yet); the
  `drm_fit_df` df under-count spawned as a background task (task_befac4a1).

## 8. Consistency Audit

- Noether (math_consistency_reviewer) reviewed the change: CONFIRMED on all five points —
  `scale_side_only` semantics correct; the `beta_sigma` marginalization legitimately
  debiases a K-based scale variance component exactly as for ordinary scale REs; no
  likelihood value changes; no edge-case misfire; univariate-only is internally consistent
  (documented asymmetry with biv to close later).

## 9. What Did Not Go Smoothly

- First coverage-driver cut used `ci[1,1]` matrix indexing; `confint(..., method="profile")`
  returns `$lower`/`$upper` — fixed to match `coverage-runner.R`.
- The biv scale-side test hit a grammar wall ("partial location-scale blocks not
  implemented") before the REML gate, so that sub-assertion was replaced by the
  mean+scale-spanning univariate case (which does reach the gate).

## 10. Known Residuals

- **`drm_fit_df` scale-side df under-count (pre-existing, flagged not fixed).** It re-adds
  `ncol(X$mu)` under REML but never `ncol(X$sigma)` when `beta_sigma` is also marginalized,
  so df/AIC under-counts the scale fixed effects for every scale-side REML fit (ordinary,
  phylo, and now C1). Likelihood value unaffected. Broader blast radius than C1 and needs a
  convention decision → spawned as task_befac4a1, left for review.
- Biv C1 (scale-side spatial/animal/relmat under REML) is unbuilt — needs its own campaign.
- `inference_ready` certification here is from the profile channel at the g-ladder; not
  wired into the board TSV / two-tier gate driver yet (the cells are new, not in the 8).

## 11. Team Learning

- A capability gated "not validated yet" can be unlocked purely R-side when the C++ already
  computes it correctly — the recovery bypass (`assignInNamespace`) proves the mechanism
  before the gate is touched. Validate with recovery THEN coverage; admit on recovery,
  certify the tier on coverage.
- Reviewers earn their keep on the neighbours: Noether's df finding is a real correctness
  item the change itself did not introduce but made more reachable.

## 12. Cross-Product Coverage

- **covers ✓**: univariate `sigma ~ spatial()/animal()/relmat()` structured effects
  (intercept + slope, and intercept-only) under REML — admitted, recovery-certified
  (400/400 debiasing, bias→0), coverage `inference_ready` (≥0.926 vs 0.91 floor).
- **does NOT cover ✗**: mean-side non-phylo REML (rejected, no evidence); bivariate
  scale-side (rejected, no evidence); `supported` tier (deferred); the `drm_fit_df` df fix;
  wiring these new cells into the board TSV / two-tier gate driver.
