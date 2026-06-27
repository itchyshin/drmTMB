# After-task: q4-location coverage grid — measured, INCONCLUSIVE (pdHess-censored)

Meta: 2026-06-27 · Claude (ultracode) · third local SR475 coverage lane.
Companion to `2026-06-27-local-coverage-grids-sigma-q2.md`.

## 1. Goal

Now that drmTMB runs locally and the q4-location D4 defect was confirmed fixed,
run the q4-location coverage grid (16 direct-SD targets), verify, and bank.

## 2. Implemented / Result

- **Confirmed the D4 fix live**: a q4-location fit now populates `estimate_sd`
  (`mean_est_sd = 0.4457`, non-NA) — the `mu1:provider(...)` `sdpars$mu` key is
  correct. This un-HOLDs the q4-location runner (D1 gate fixed, D2 surfaced via
  finite-fraction columns, D4 confirmed; a clean full run resolves D3's stale
  artifact).
- **Ran the SR475 q4-location grid** (16 targets × 475 reps, parallel). All
  475/475 converged, no errors.
- **Fisher verdict: INCONCLUSIVE (pdHess-censored) — NOT a positive result.**
  - `is_boundary` is dominated by `!pdHess` (non-invertible joint bivariate
    Hessian), NOT a variance-at-bound flag (censored reps have median SD ~0.39).
    Added a clarifying comment at the flag; the full relabel is a follow-up.
  - Wald-finiteness is deterministically equal to pdHess-pass (0 of 2568 boundary
    reps are Wald-finite), so Wald coverage is conditional on the pdHess subset
    and selection-biased optimistic; **23–49%** of reps are censored
    (`wald_finite_frac` 0.51–0.77). Imputation bounds span up to ~45 points for
    phylo/spatial — the survivor coverage is undetermined.
  - **Slope-SD survivor over-coverage (0.98–0.997) is a censoring artifact**, the
    least trustworthy number. The only qualified finding: **location RE-intercept
    SD profile coverage ~0.90–0.93** (mild under-coverage, imputation-stable).
- **Banked** 16 q4-location rows into
  `docs/dev-log/dashboard/structured-re-slope-coverage-results.tsv`
  (verdict `pdhess_censored_*`); preserved the raw grid; registered the lane in
  the validator. Linked cells (`qseries_<provider>_q4_mu1_mu2_one_slope`) stay
  `coverage_status = planned`.

## 3. Checks Run

- D4 confirmation fit + full grid ran locally on drmTMB 0.1.4.
- `Rscript --no-init-file -e 'parse(...)'`: OK; `python3 tools/validate-mission-control.py`:
  `mission_control_ok`, 33 slope coverage-results rows.
- **Fisher** (`inference_reviewer`) verified: confirmed `is_boundary == !pdHess`
  (0/2568 boundary reps Wald-finite), quantified the selection bias (censored reps
  have lower `estimate_sd`), and inverted the naive slope/intercept read.

## 4. Known Residuals / Next

- q4-location coverage is INCONCLUSIVE; `supported` stays blocked for all 16
  Wald targets. The pdHess-failure rate (23–49%) is the same q4 Hessian-geometry
  blocker flagged in the handover — a real engine/identifiability issue, not a
  compute one. Running more reps will NOT fix it (the censoring is structural).
- Runner follow-up (Fisher): rename/split `is_boundary` into `non_pdHess` vs an
  actual at-bound check, and have the summary report imputation-robust bounds (or
  `wald_coverage = NA` when `wald_finite_frac < 0.9`) before any re-run is banked
  as a pass.
- Commits are LOCAL (the `Bash(git push *)` deny rule blocks push).

## 5. Team Learning

A near-nominal survivor coverage with a 51–77% finite fraction is not evidence —
it is a selection artifact. The `wald_finite_frac` column (added as the D2 fix)
was exactly what made the censoring visible; without it the runner's clean-looking
`wald_coverage` would have read as a pass. The honest q4-location result is a
*negative-with-a-mechanism*: the bivariate q4 location covariance is
pdHess-fragile on g=8, and that fragility — not coverage — is what the grid
measured.
