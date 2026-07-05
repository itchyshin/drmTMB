# After Task: M3 — q12 two-slope all-four admission (104/104 arc)

Meta: 2026-07-05 · Claude (Shannon) · branch `drmtmb/fix-family-conventions` · M3 of
the Q-Series 104/104 arc. Continues M2 (q6, merged at e6f87ca8).

## 1. Goal

M3: fill the four "broader q8" placeholder rows (`qseries_<provider>_q8_planned`,
phylo/spatial/animal/relmat) with a concrete broader model and admit them on
honest recovery, taking the Gaussian surface to 102/104. Maintainer chose
(option b) a genuinely broader model: the **q12 two-slope all-four block**
`(1 + x + z | p | id)` on mu1/mu2/sigma1/sigma2 — 12 endpoints, 12 SD + 66
among-endpoint correlations. `pdHess=FALSE` is OK (profile/bootstrap; ELR
excluded) per the locked doctrine (LESSONS 2026-07-05; Shinichi: "we always have
profile and bootstrap").

## 2. Implemented

- **Parser/assembly admission, no C++** (`R/drmTMB.R`): generalized the all-four
  validation predicate from intercept-plus-one-slope to
  `structured_term_is_intercept_plus_slopes` (the M2 predicate), so the labelled
  two-slope all-four block routes through the existing q-generic covariance
  finalize (which builds `q = 4 * n_coef = 12`). Block-diagonal and mismatched
  layouts stay rejected. New test `tests/testthat/test-structured-re-q12-all-four.R`
  (16 asserts, incl. the routing invariant: 12 SDs profile-ready, 66 correlations
  not); the obsolete M2 "all-four two-slope rejected" guard updated to a
  q12-builds assertion.
- The concrete q12 cell (`(1 + x + z | p | id)` all four) was the exact boundary
  M2's grammar change had reserved; M3 opens it with one contained validation edit.

## 3a. Verdict

**q12 two-slope all-four builds a q=12 covariance (66 correlations) and recovers
its known 12x12 Sigma at adequate n for all four providers, with `pdHess=FALSE`
(genuine weak-ID of the 66-correlation block; routed through profile/bootstrap).**
It is the arc's biggest covariance and the two-slope generalization of the q8
all-four one-slope cell.

## 3b. Inference doctrine (unchanged)

`pdHess=FALSE` is not failure (LESSONS 2026-07-05). The 12 SDs are direct profile
targets; the 66 correlations are derived (Wald-unavailable) -> parallel profile
(primary) + bootstrap (fallback); ELR excluded. Intervals/coverage are the
Phase-5 follow-on.

## 4. Files touched

- `R/drmTMB.R` (all-four validation predicate; no C++), new q12 test, updated q6 test.
- `docs/dev-log/simulation-artifacts/2026-07-05-m3-q12-recovery/` (helpers, runner, per-provider TSVs, log).
- Dashboard/status admission (support-cells 4 rows, ledger + status + release-check
  sidecars regenerated, claim guard, closure-triage, high-q audit, readiness-reset,
  mission-control validator [new q12 dimension + q12 runtime allowlist], conversion
  test), grammar doc (q6 backfill + q12), design-218, NEWS.

## 5. Checks run (streamed recovery evidence)

Recovery of a known 12x12 Sigma (66 correlations, offdiag |rho| 0.135-0.646),
per-fit stream. All fits `se=TRUE` (real `pdHess`, not the isTRUE(NULL) trap).

| provider | n_group | pdHess | cap_sat | rmse |
|---|---|---|---|---|
| phylo | 128 / 256 / 512 | FALSE | FALSE | 0.216 / 0.168 / 0.136 |
| spatial | 64 | FALSE | FALSE | 0.287 |
| animal | 64 / 128 | FALSE | FALSE | 0.221 / 0.205 |
| relmat | 64 / 128 | FALSE | FALSE | 0.221 / 0.205 |

All four recover a known Σ with no cap-saturation (max|rho| < 0.99). The
rmse-falls-with-n evidence is a **phylo** result (0.216→0.136 across n=128→512);
spatial rests on a single n=64 point and animal/relmat move only 0.221→0.205
(n=64→128) — the dense providers rest on a single adequate-n point each (disclosed).
**Compute honesty:** dense-covariance q12 is expensive (spatial n=128 ~40 min,
n=256 intractable >61 min), so spatial/animal/relmat rest on n=64/128 while phylo
carries the fuller curve to n=512; animal and relmat coincide (same AR(1) K).
This is recovery-only evidence, not a multi-n Santi-scale curve for the dense
providers. `test-structured-re-q12-all-four.R`: 16 pass (via `load_all`; the
installed drmTMB v0.1.4 library is stale and must be reinstalled before any
`devtools::test()`/CI run — the source parser edit is correct, the binary lags).

## 6. Tests of the tests

Deterministic 12x12 PD truth (no RNG in the truth builder). DGP imposes each
provider's own among-group covariance A and simulates A(x)Sigma; recovery targets
Sigma's 66 upper-tri correlations. The build test asserts q=12, canonical
dpars/coef order, 66 theta, 12 SDs, 66 corpairs, 66 derived correlation targets.

## 7a. Issue ledger

No GitHub issue. PR #730 merged (M2). This continues on `drmtmb/fix-family-conventions`.

## 8. Consistency audit (4-lens gate)

- **Curie** (recovery): q12 recovers its known 66-correlation Sigma at adequate n
  for all four; no cap-saturation; small-n rmse rough but improving; dense
  compute-limited (disclosed).
- **Noether** (symbolic<->R<->TMB): **CONSISTENT**. Endpoint order/q=12 exact;
  66 theta = choose(12,2) map to correct labels (no transposition); same q-generic
  `drm_qgt2_corr_matrix`/separable kernel as q6/q8; q4/q6/q8/univariate neighbours
  unchanged (the predicate reduces to one-slope at length 2); block-diagonal /
  mismatched / partial layouts stay rejected. One cosmetic display-only defect
  fixed: the all-four block summary `term$label` named only the first slope
  (`1 + x`), dropping `z` — aligned with the location-only finalize
  (`paste(variables, collapse = " + ")`); not used by any SD/correlation label or
  likelihood path.
- **Fisher** (inference): **HONEST** (verified on a live q12 fit). The 66
  correlations are `profile_ready=FALSE` with NA link (a Wald CI errors — no
  overclaim possible); the 12 SDs are direct profile targets; pdHess=FALSE is a
  real sdreport read (se=TRUE), genuine weak-ID like M1's q8, not the isTRUE(NULL)
  trap; no status field carries inference/coverage/supported (all negations).
  Two tightenings applied: (1) the q12 test now pins the routing invariant
  (`sd profile_ready` TRUE / `cor profile_ready` FALSE); (2) after-task §5 now
  states the rmse-falls-with-n evidence is phylo-specific (dense providers rest on
  a single adequate-n point each).
- **Rose** (claims): **SIGN_OFF_WITH_CHANGES**. All four gates + the 22k-assertion
  conversion test pass; every sidecar regenerated coherently to 98->102 (Gaussian
  core 67/67 = 100%, 2 post-v1.0 non-Gaussian rows); the assume-ten-more stale-count
  sweep came back **clean** (every `98/104`/`94.2%`/`63/67` hit is a correctly-frozen
  historical/handover reference, not a live surface; the README/ROADMAP "q4_all_four_one_slope"
  q8 one-slope cell is confirmed distinct from the `_q8_planned` q12 cell, so those
  lines are not stale). Non-blocking fixes applied this pass: NEWS "or better" ->
  "basic-working-or-better role" (two Gaussian rows are `diagnostic_only`, arguably
  below point-fit); after-task "14 asserts" -> 16; the stale installed-library caveat
  is now recorded (§5). **cell_id: RENAME as a separate mechanical follow-up** (keep
  the `_q8_planned` key for this ship; renaming inside the admitting change risks
  conflating two edits) -> Rose and I agree; deferred (§10). Two doc-catch-up items
  Rose flagged (README/ROADMAP q6+q12 capability rows; a claim-guard capability-row
  freshness check) are folded into that follow-up (§10).

## 9. What did not go smoothly

Dense-covariance q12 at n=256 was intractable (>61 min/fit, killed after the
parallel campaign produced zero dense rows in an hour); re-probed at n=64/128 to
find a tractable scale. The first inline `$R`-variable parallel launch failed
silently (the `;`+`/dev/null` hid it); relaunched via a script file with
`&`/`wait` + captured stderr. Totoro (384 cores) was considered but does not make
a single expensive fit faster (only parallelizes many), so local n=64/128 was the
pragmatic route.

## 10. Known residuals / arc implications

- q12 admitted at point-fit/recovery; intervals/coverage are the Phase-5 follow-on.
- **cell_id debt:** the ids `qseries_<provider>_q8_planned` now hold a q12 cell
  (dimension_pattern=q12). Kept as stable keys for this ship (M2 precedent; Rose
  concurs renaming inside the admitting change risks conflating two edits). Tracked
  follow-up: one mechanical rename to `_q12_all_four_two_slope` across the 6 files /
  25 occurrences (validate-mission-control.py, conversion-contracts test, and four
  dashboard/sidecar TSVs; no C++/public API/bridge key), re-running all four gates +
  the conversion test.
- **README/ROADMAP capability-row lag (q6 + q12), deferred by design.** README.md
  rows 269-272 and ROADMAP.md 479-480 describe the q8 one-slope all-four cell but not
  the q6 (M2) or q12 (M3) two-slope surfaces. This is a *uniform* lag: M2 shipped the
  same pattern (status board + grammar doc + NEWS + design-218 updated; the curated
  capability catalogs left to a separate sweep). Partially adding q12 now while q6
  stays absent would create a worse q12-present/q6-missing asymmetry, so both are
  folded into the cell_id rename follow-up as a single doc-catch-up (plus Rose's
  proposed claim-guard capability-row freshness check, which would catch this class
  systematically). The status board, NEWS, and `docs/design/01-formula-grammar.md`
  already reflect q6 and q12, so no live surface overclaims; this is catalog lag, not
  contradiction.
- Dense q12 Santi-scale (n>=256) recovery is compute-limited; a Totoro/DRAC
  campaign could deepen it later.
- After q12: 102/104 (Gaussian-complete). Only the 2 non-Gaussian rows remain for 104.

## 11. Team learning

The arc's covariance engine is genuinely q-generic: q4 -> q6 -> q8 -> q12 all
admit via a gated grammar relaxation plus honest recovery, no C++. And: dense
structured covariance recovery cost scales steeply with q (66 correlations x
dense n-by-n ops) — right-size the recovery n to the provider's cost, and disclose
the asymmetry rather than pretend a uniform Santi-scale curve.
