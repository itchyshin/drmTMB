# After Task: M2 — q6 two-slope location admission (104/104 arc)

Meta: 2026-07-05 · Claude (Shannon) · branch `drmtmb/fix-family-conventions` · M2 of
the Q-Series 104/104 ultra-plan. Continues M1 (covariance-recovery verdict).

## 1. Goal

M2 of the 104/104 arc: admit the four **q6 two-slope location-only** structured
rows — `(1 + x + z | p | id)` in `mu1` and `mu2` for `phylo()`, `spatial()`,
`animal()`, `relmat()` (six endpoints: mu1/mu2 × {(Intercept), x, z} → 6 SDs + 15
among-endpoint correlations) — on honest **fit + recovery** evidence at
Santi-scale n. Reuse the M1 streaming-sim discipline and DGP pattern. pdHess=FALSE
is not failure (route intervals through parallel profile/bootstrap; ELR excluded).
Do NOT rewrite the covariance engine (M1 proved it works). Do NOT inflate
coverage/support wording. Keep Julia optional.

## 2. Implemented

M1 said the covariance engine already recovers high-q Σ; M2's blocker was the
**parser/assembly gate**, not the engine. The change admits the labelled
two-slope location block and routes it through the existing q-generic
among-endpoint covariance machinery (the same path q4-location-slope and the q8
all-four block use). Surgical, gated so no neighbour model changes:

- `R/parse-formula.R` `parse_structured_bar_term()`: new branch admits
  `1 + x + z (+ …)` → `coef_names = c("(Intercept)", vars…)` **only when a
  covariance label is present**. Unlabelled multi-slope keeps its prior rejection.
- `R/drmTMB.R`: new predicate `structured_term_is_intercept_plus_slopes()`
  (intercept + ≥1 matching slopes; reduces exactly to the one-slope predicate at
  length 2) and `structured_term_has_labelled_intercept_plus_slopes()`.
- `R/drmTMB.R`: the three per-provider mu extraction gates
  (`extract_gaussian_mu_phylo_term`, `…spatial_term`, `…known_term`) accept
  intercept-only / slope-only / intercept-plus-slopes via the new predicate.
- `R/drmTMB.R` `combine_univariate_structured_terms()`: rejects labelled
  multi-slope in the univariate path (prevents a q3 leak).
- `R/drmTMB.R` `validate_matching_structured_biv_location_coef()`: the
  `both_one_slope` gate generalized to `both_intercept_plus_slopes`.
- `R/drmTMB.R` `finalize_biv_structured_mu_term()`: label formatting for ≥2 coefs
  (the endpoint/covariance construction was already q-generic).

No `src/drmTMB.cpp` change: q6 flows through the identical q-generic C++ path as
q8 (`drm_qgt2_corr_matrix` / `drm_separable_cov_logdet_quad`), confirmed by
Noether.

## 3a. Verdict

**q6 two-slope location parses, builds a q=6 covariance (15 correlations), and
recovers its known Σ with `pdHess=TRUE` at adequate n — for all four providers.**
q6 (15 correlations) is materially better-identified than the q8 all-four block
(28 correlations, whose `pdHess=FALSE` persists even at 1024 groups): q6 reaches
`pdHess=TRUE` and clean recovery, so it is admitted as a point-fit/recovery row,
not deferred to the reduced-rank estimation arc that q8 needs.

## 3b. Inference doctrine (unchanged from M1; Shinichi 2026-07-05)

The six SDs are direct profile targets (profileable once the TMB object is
retained); interval_status stays planned pending the profile/coverage run. The
fifteen among-endpoint correlations are **derived** (Wald-unavailable, endpoints
NA), so correlation intervals route through **parallel profile** (primary) +
**bootstrap** (fallback); **ELR is excluded**. This matches the pre-existing ordinary-q6 recovery contract
(`test-phase18-biv-gaussian-q6-location-recovery.R`). Intervals/coverage remain a
Phase-5, Fisher-gated follow-on; M2 admits fit + recovery only.

## 4. Files touched

- `R/parse-formula.R`, `R/drmTMB.R` (parser + assembly admission; no C++).
- `tests/testthat/test-structured-re-q6-location.R` (new: 4-provider build +
  extractor assertions + 3 rejection guards).
- `docs/dev-log/simulation-artifacts/2026-07-05-m2-q6-recovery/` (helpers +
  streaming runner + results TSV + log + summary).
- Dashboard/status admission (§ below): support-cells TSV (4 rows), regenerated
  release ledger + status, high-q status-audit, closure-triage, claim guard.

## 5. Checks run (streamed recovery evidence)

Recovery of the known 6×6 Σ (offdiag |ρ| 0.23–0.65), streamed per-fit. Metric =
per-correlation RMSE of `corpars[[provider]]` (15 upper-tri) vs truth;
cap-saturation flagged at |ρ|>0.99.

_phylo (recovery-vs-n curve, seed 20260705; se=TRUE):_

| n_group | n_obs | conv | pdHess | max\|ρ\| | rmse | frob |
|---|---|---|---|---|---|---|
| 64 | 384 | 1 | TRUE | 0.836 | 0.159 | 0.871 |
| 128 | 768 | 0 | TRUE | 0.750 | 0.158 | 0.866 |
| 256 | 1536 | 0 | TRUE | 0.689 | 0.106 | 0.582 |
| 512 | 3072 | 0 | TRUE | 0.641 | 0.058 | 0.319 |
| 1024 | 6144 | 0 | TRUE | 0.643 | 0.061 | 0.334 |

phylo n=512 multi-seed (real, varying): rmse 0.058 / 0.065 / 0.090, all pdHess=TRUE.

_spatial / animal / relmat (small-n boundary + adequate-n recovery). Dense
covariance (~8 min/fit at n=256) so single-n with 1–2 seeds; the pdHess flip and
recovery, not a multi-n curve, are the point:_

| provider | n_group | conv | pdHess | max\|ρ\| | rmse | seeds |
|---|---|---|---|---|---|---|
| spatial | 64 | 1 | FALSE | 0.860 | 0.270 | 1 (boundary) |
| spatial | 256 | 1 | TRUE | 0.838 | 0.188 | 1 |
| animal | 64 | 0 | TRUE | 0.799 | 0.183 | 1 |
| animal | 256 | 0 | TRUE | 0.640/0.690 | 0.072 / 0.055 | 2 |
| relmat | 64 | 0 | TRUE | 0.799 | 0.183 | 1 |
| relmat | 256 | 0 | TRUE | 0.640 | 0.072 | 1–2 |

All four providers reach pdHess=TRUE with clean recovery (rmse ≤ 0.19, no
cap-saturation) at adequate n; spatial's n=64 pdHess=FALSE is the data-size
boundary (M1's failure→success-with-n flip), not engine failure. animal and
relmat share the same AR(1) relatedness matrix, so their fits coincide (A = K).

`test-structured-re-q6-location.R`: 55 assertions pass (4 providers build q=6 +
15 corr + extractors; 3 rejection guards hold). Affected R suites
(test-parse-formula, test-phylo/spatial/animal-relmat-gaussian,
test-structured-effects, test-structured-re-q2-rejections, test-biv-gaussian):
0 failures, incl. the univariate two-slope rejection.

`test-structured-re-conversion-contracts.R` (22271 assertions) reads the
generated release-status/ledger/sidecars and pins the surface counts, so it
**required updating** as part of the admission: after the status regeneration it
initially failed on the 94→98 counts, the closure-triage high-q bucket counts
(8→12 / 8→4), the readiness-reset counts (59→63 / 8→4), and the next-candidate
list (q6 rows replaced by q8). All were updated to the regenerated reality
(count-asserted so no silent miss) and it now passes 22271/0 — see §9.

## 6. Tests of the tests

The recovery truth is a fixed, deterministic PD 6×6 correlation (no RNG in the
truth, so per-replicate seeds genuinely vary — an earlier version accidentally
reset the seed via the truth default-arg and collapsed all seeds to one dataset;
fixed). The DGP imposes each provider's own among-group covariance A (tree /
coords precision / AR(1) K) and simulates from A⊗Σ, so recovery targets Σ's 15
correlations. The build test asserts q=6, canonical dpars/coef order, 15 theta,
6 SDs, 15 corpairs, and 15 derived correlation targets.

## 7a. Issue ledger

No GitHub issue opened/closed. PR #730 (94/104 checkpoint) unchanged. This work
sits on `drmtmb/fix-family-conventions`.

## 8. Consistency audit (4-lens gate)

- **Curie** (recovery): q6 recovers its known Σ; pdHess=TRUE at adequate n for all
  four providers; cap-saturation absent; small-n pdHess=FALSE is data-insufficiency
  per the data-size rule.
- **Noether** (symbolic↔R↔TMB): CONSISTENT. Endpoint/covariance mapping exact and
  canonical; q6 uses the identical q-generic C++ path as q8; no neighbour model
  change; no label/boundary leaks; interactions/transformations rejected.
- **Fisher** (inference): **HONEST** (verified against the artifacts, not the
  summary). Confirmed the truth Σ is a real recovery test; pdHess=TRUE at adequate
  n for all four; derived-correlation → profile/bootstrap routing is
  structurally enforced in `R/profile.R` (correlations get `profile_ready=FALSE`,
  NA link, so no Wald endpoint is constructible); ELR exclusion correct; small-n
  pdHess=FALSE correctly framed as data-insufficiency. Two wording tightenings
  applied: (1) the claim boundary now discloses the phylo-curve-vs-dense-n=256
  asymmetry so phylo's curve does not silently vouch for the dense providers;
  (2) the SDs are described as "direct profile targets (profileable once the TMB
  object is retained)", keeping the estimation claim separate from an interval
  claim (interval_status stays planned).
- **Rose** (claims): **SIGN_OFF_WITH_CHANGES** (changes applied). The 94→98
  practical-surface move is honest (auto-derived from fit_status=point_fit; the
  claim boundary disclaims interval/coverage/supported/STAN; q8 correctly stays
  planned; no interval/coverage/authority moved). Rose's "assume ten more" caught
  a **fourth generator I had not run** — `tools/qseries_v1_release_check.py`
  writes a family of release-audit sidecars (next-candidate-review, preflight
  report, first-four contracts) that still listed q6 as a planned candidate and
  hardcoded 94/104, and `test-structured-re-conversion-contracts.R` both calls
  that checker and pins the old counts, so that R test was red. All fixed:
  regenerated the sidecars (`--write-report --write-candidates`), updated the
  conversion-contracts test, and re-verified all four gates + the test green.

## 9. What did not go smoothly

The first recovery helper reset the RNG inside the truth builder (a default
argument), which clobbered the per-replicate seed and made every "seed" produce
the same dataset — caught because a phylo n=512 multi-seed run returned identical
RMSE to four decimals. Fixed by making the truth deterministic (no RNG). The
first n-ladder also over-reached (n=1024 across all four providers); the dense
providers cost ~7 min/fit at n=256, so the ladder was right-sized to the model
per the streaming discipline. Concurrent R jobs sharing one results TSV also lost
rows to append collisions (R `cat(append=TRUE)` is not concurrency-safe here) —
the dense providers were re-run sequentially.

**The status-accounting miss (Rose caught it).** I regenerated the ledger +
release-status via `qseries_v1_release_ledger.py` and updated the closure-triage,
high-q audit, readiness-reset, and mission-control validator — and the three
validators I knew about went green. But there is a **second, separate generator**
family, `qseries_v1_release_check.py` (`--write-report`/`--write-candidates`),
that writes the next-candidate-review, preflight report, and first-four contract
sidecars off the same source TSV, plus a `--check-report`/`--check-candidates`
gate that `test-structured-re-conversion-contracts.R` exercises. I did not run it,
so a fourth gate and a 22k-assertion R test were left red while the other three
passed — a partial-regeneration that *looked* complete. Rose's "assume ten more"
sweep found it; regenerating the sidecars and updating the test's pinned counts
closed it.

## 10. Known residuals / arc implications

- q6 admitted at point-fit/recovery; **intervals + coverage + STAN cross-check are
  the Phase-5 follow-on** (Fisher-gated), not part of M2.
- The `_planned` suffix in the cell_ids (`qseries_phylo_q6_planned`, …) is now a
  historical name; renaming was declined this slice because ~10 files (validator,
  a 22k-assertion test, release-audit TSVs) reference the ids. Follow-up: a tracked
  rename once the arc settles.
- **Narrative reconciliation (non-blocking):** `docs/design/59-...` (lines ~39/63/79)
  still describes structured q6 as "smoke artifact routing" rather than point-fit
  recovery. Per the doc-218 authority rule (validator-owned dashboard is authority;
  narrative reconciled later) this is acceptable debt; update opportunistically.
- Next milestone **M3 = q8 admitted (4 providers, recovery)** — but q8 pdHess=FALSE
  persists, so q8 admission depends on the reduced-rank factor-analytic estimation
  arc (its own methods work), not just parser admission.
- Noether note: a pre-existing duplicate q>2 phylo covariance block in C++
  (production `u_phylo` path vs a REPORT-only probe path); not on the q6
  likelihood, but a divergence risk if either is edited without the other.

## 11. Team learning

The "high-q blocker" was never the covariance engine — M1 proved that, and M2
confirms the remaining gate for q6 was purely the parser/assembly reserving
multi-slope terms. The engine's among-endpoint covariance is genuinely
q-generic: admitting a new q-level is a gated grammar relaxation plus honest
recovery evidence, not engine surgery. And: never let a simulation's truth touch
the global RNG stream when it is a default argument — it silently defeats
multi-seed replication.

**Status accounting has more than one generator, and green-on-the-ones-you-know
is not green.** A q-series status move must regenerate BOTH
`qseries_v1_release_ledger.py` (ledger + release-status) AND
`qseries_v1_release_check.py` (`--write-report --write-candidates`: preflight +
candidate + first-four sidecars), then run all four gates —
`validate-mission-control.py`, `qseries_v1_release_ledger.py --check
--check-status`, `qseries_v1_claim_guard.py`, `qseries_v1_release_check.py
--check-report --check-candidates` — plus `test-structured-re-conversion-contracts.R`
(which pins the generated counts and the candidate list). The standing "regenerate
the ledger" rule is too narrow; widen it to "regenerate every q-series audit
generator and run all four gates + the conversion-contracts test." A future
safeguard would wire the `release-check --check-*` gate into the same pre-commit
lane as the other three so a partial regeneration cannot look complete.
