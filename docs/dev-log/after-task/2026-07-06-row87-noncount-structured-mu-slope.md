# After Task: Non-count Structured Mu One-Slope — Row 87, the final cell (104/104)

## 1. Goal

Admit the last `planned` Q-Series board cell,
`qseries_nongaussian_structured_slope_neighbors_recovery` (row 87), honestly and
recovery-only, closing the practical v1.0 fit surface at **104/104**. The row is a
catch-all for "non-count OR labelled/multiple structured non-Gaussian slope
variants". The honest representative is a **non-count family structured `mu`
one-slope**; the maintainer chose to build **all three** near-equivalent candidates
and admit on the evidence ("and see"). This is a fit/recovery milestone, not a
"package complete" claim — intervals/coverage remain a separate, larger arc.

## 2. Implemented

Three non-count family × provider structured `mu` **one-slope** cells, all
recovery-only, all **no C++**:

- `Gamma()` × `relmat(1 + x | id, K)`
- `student()` × `spatial(1 + x | id, coords)`
- `beta()` × `animal(1 + x | id, pedigree/A)`

The engine change is a per-family **validator relaxation**: the three `mu`
structured-term validators now accept `structured_term_is_intercept_only(term) ||
structured_term_is_intercept_one_slope(term)`, mirroring the count gate at
`R/drmTMB.R:7211`. No `src/*.cpp` change (`git diff src/` empty across the arc).
The board row was flipped `planned → point_fit / extractor_ready` recovery-only.

## 3a. Decisions and Rejected Alternatives

- **Direction = close cheaply, then open the C++ arc (maintainer).** The one no-C++
  representative is genuinely no-C++; the C++-heavy rest (labelled/multiple/count-σ/
  ZI/q2–q4 structured covariance) is the *next* arc, not this cell.
- **Representative = all three families (maintainer), admit on evidence.** One board
  row, three demonstrations — stronger than a single possibly-lucky family, not
  padding.
- **Rejected the count-gaming shortcut** (Poisson-phylo slope-only): count/unlabelled/
  single-slope is none of row 87's "non-count OR labelled/multiple"; it would move the
  count without delivering the capability.
- **Added a non-identity (AR(1)) relatedness check** for gamma/beta after Noether noted
  the crossed ladder used `K = I` / `A = I` (identity); the AR(1) check exercises the
  non-diagonal precision path directly.
- **Left the closure-triage subsystem untouched** (see §10), matching the row-105
  precedent.

## 3b. Mathematical Contract

A `1 + x` structured term produces `q = 2` columns (intercept field, slope field),
both targeting `mu` (same `dpar`). The C++ `has_cross_dpar_phylo` gate
(`src/drmTMB.cpp`) is therefore FALSE, routing to the independent-per-column-SD
branch: `mu(i) += phylo_mu_value(i, k) * u_phylo(...)` for `k ∈ {0,1}`, each with its
own `log_sd_phylo(k)` and `Q_phylo`-weighted quadratic, no cross-correlation term.
The family enters only in the downstream observation density (standard TMB Gamma/
Student/beta), so it is inert to how `mu` was built — hence no C++ (Noether verified).

## 4. Files Touched

- `R/drmTMB.R` — three `mu` structured-term validators relaxed (`:7456`, `:7644`, `:7702`).
- `tests/testthat/test-nongaussian-structured-mu-slope.R` — new admission + boundary test.
- `docs/dev-log/simulation-artifacts/2026-07-06-m5-row87-recovery/` — ladder, control,
  non-identity check, README, raw/summary TSVs, reproducible drivers.
- Board sidecars: `structured-re-q-series-support-cells.tsv`,
  `structured-re-nongaussian-status-audit.tsv`,
  `structured-re-q-series-v1-release-ledger.tsv` (regenerated),
  `structured-re-q-series-v1-readiness-reset.tsv`.
- Release-audits (regenerated via `qseries_v1_release_check.py --write-candidates
  --write-report`): 7 candidate/contract sidecars + `q-series-v1-release-status.md`.
- Tools: `qseries_v1_claim_guard.py` (status phrases), `validate-mission-control.py`
  (widget_state + count expectations).
- Design: `docs/design/59-*.md`, `docs/design/218-*.md`.

## 5. Checks Run

- **S0 spike:** all three fit, converge, `pdHess=TRUE`, extractor emits both SDs; `git
  diff src/` empty.
- **RED→GREEN:** stashing the relaxation makes the admission test error ("intercept-only
  structured terms"); restoring passes 17/17.
- **Recovery ladders:** crossed `n_lvl ∈ {10,20,30}` × 30 seeds. gamma/beta 90/90
  converged pdHess=TRUE; student 83/90 (26/28/29). RMSE of both SDs falls with levels.
- **Null-slope control:** slope SD → ~0 (0.008/0.003/0.037) with intercept SD recovered.
- **Non-identity AR(1):** gamma/beta 20/20 converged, means on truth.
- **Neighbouring boundary test:** 71/71 (sigma/nu/zi/hu slope rejections intact).
- **Conversion-contract test:** 22257/22257.
- **All four board validators green** (MC / claim guard / release ledger `--check` /
  release check `--check-report --check-candidates`), clean exit codes.

## 6. Tests of the Tests

- The admission test is genuinely RED without the relaxation (demonstrated by stashing
  `R/drmTMB.R`), so it gates on the engine change, not a tautology.
- The null-slope control shows the estimator does not invent slope heterogeneity;
  combined with RMSE-falls-with-levels this demonstrates the intercept and slope SDs are
  separately identified.
- Boundary preservation asserts multiple-slope (`1 + x + z`, rejected at parse) and
  labelled (`1 + x | p | id`) forms still reject.

## 7. Issue Ledger

No GitHub issue is associated with this cell; tracking is via the board sidecars, this
after-task, and `check-log.md`.

## 8. Consistency Audit

Board: 99 `point_fit` + 3 `supported` + 2 `diagnostic_only` = 104, zero `planned`.
Practical surface 104/104, Gaussian core 67/67, basic-distribution recovery 37/37,
post-v1.0 design 0/104, `supported` still 0/104. All primary status surfaces agree;
all four validators green. The 4-lens gate signed off: Curie CLEAN_WITH_CAVEAT, Noether
CONSISTENT_WITH_NOTE, Fisher HONEST, Rose SIGN_OFF_WITH_NOTE.

## 9. What Did Not Go Smoothly

- **Closure-triage taxonomy detour.** A first attempt to move row 87 to the closure
  `recovery_only` bucket broke the validator: its closure counts are a hardcoded dict,
  and its `non_gaussian_rejected` bucket actually holds the `point_only` cells (a
  misnomer). Reverted and left untouched (see §10).
- **Ledger/release-status are generated, not hand-edited.** Hand-edits were superseded
  by regenerating from source (`--write` / `--write-report`); the generated values are
  authoritative.

## 10. Known Residuals

- **cell_id `_planned` suffix — RESOLVED (2026-07-06 follow-up).** The id kept its suffix
  during the flip (stable key), then a follow-up renamed it to
  `qseries_nongaussian_structured_slope_neighbors_recovery` in lockstep across the live
  surfaces, per the row-105 `_rejected`→`_recovery` precedent.
- **Closure-triage — reconciled (same follow-up).** Row 87 was moved out of the
  `non_gaussian_planned` closure bucket into the point-only-holding bucket, with the coupled
  validator closure dict + queue dict + queue sidecar updated in lockstep; the 16-bucket
  total stays 104 and all validators are green. The remaining `rejected`-bucket misnomer (it
  holds `point_only` cells; pre-existing, ~18 cells incl. row 105) — and the ideal relabel to
  `point_only` — is left as a separate legacy cleanup, because a clean relabel cascades into
  the queue's dual-purpose `intentional_rejections_hold` row and the dual-use
  `non_gaussian_rejected` widget_state.
- **student_spatial small-sample caveat.** Convergence 86.7% → 96.7% across the ladder;
  the `claim_boundary` and artifact carry `n_levels ≥ 20`.
- **S7 pending:** full local suite / `R CMD check --as-cran` before merge (direct-DLL
  builders), then PR + CI-green merge.

## 11. Team Learning

- **Use the board validators as the check-loop.** Editing the master (`support-cells`)
  then running `validate-mission-control.py` surfaces every derived inconsistency
  precisely; regenerate generated sidecars (`ledger`, `release-status`, release-audits)
  rather than hand-editing.
- **Hardcoded validator expectations track the board.** Admissions must update the
  validator's per-cell widget_state and count dicts, not just the sidecars.
- **Address reviewer notes, don't just disclose them.** Noether's `K=I`/`A=I` note became
  a non-identity AR(1) check that closes the gap rather than a caveat.
