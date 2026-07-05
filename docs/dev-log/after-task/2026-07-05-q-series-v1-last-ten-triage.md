# After Task: Q-Series v1 Last-Ten Row Triage

Meta: 2026-07-05 · Claude takeover session · branch `drmtmb/fix-family-conventions`
(HEAD `0ce8b919`) · draft PR #730

## 1. Goal

Take over the Q-Series v1 practical-surface arc. Stabilize the pushed branch and
draft PR, re-audit claim language with Rose/Fisher/Ada/Grace, then triage the
remaining `10/104` post-v1 rows into economical finish-now work versus post-v1,
using economy as the rule. Execute only cheap deterministic finish-now work;
otherwise document the post-v1 boundary. Keep drmTMB primary and Julia optional.

## 2. Implemented

- Confirmed branch and Mission Control truth reproduce the handover exactly:
  `practical_v1_surface=94/104 (90.4%)`, `gaussian_core=59/67`,
  `basic_distribution_recovery=35/37`, `exact_inference_ready=8/104`,
  `supported_authority=0/104`, `post_v1=10/104`, `rows_to_100=10`.
- Trimmed `.github/workflows/R-CMD-check.yaml` so routine `pull_request` and
  push-to-main runs check `ubuntu-latest` only; the full 3-OS matrix now runs
  only on release tags (`v*`) and `workflow_dispatch` (commit `0ce8b919`).
  Verified live: the PR run emitted the ubuntu-only matrix.
- Opened draft PR #730 into `main` with a corrected 94/104 body drawn from the
  generated ledger `docs/dev-log/release-audits/q-series-v1-release-status.md`.
- Ran the Rose/Fisher/Ada/Grace release-candidate audit (see §8).
- Triaged the 10 remaining rows: **0 finish-now, 10 post-v1** (see §3a, §10).

This slice moves **no support cell** and authorizes **no** coverage, promotion,
interval, REML/AI-REML, bridge, or public-support claim.

## 3a. Decisions and Rejected Alternatives

**Triage decision (economy rule):** a row is finish-now only if the work is
cheap, deterministic, requires no broad coverage, and creates no new inferential
authority. Every one of the 10 rows fails that test. All 10 stay post-v1.

| # | cell_id | shape | blocker class | cost | decision |
| --- | --- | --- | --- | --- | --- |
| 1 | `qseries_count_mu_simultaneous_structured_types_rejected` | nbinom2 · spatial · q1 mu | engine design: count engine has one structured field slot; needs additive multi-provider count-mu design + extractor policy | high (parser+TMB+recovery) | post-v1 |
| 2 | `qseries_nongaussian_structured_slope_neighbors_planned` | non-Gaussian · all_structured · q1 mu one-slope | design: row-specific family/provider DGP + extractor/recovery contract across a family class | high (broadest scope) | post-v1 |
| 3 | `qseries_animal_q6_planned` | biv_gaussian · animal · q6 mu1+mu2 multi-slope | engine: high-q multi-slope mean-covariance gate + recovery | high (engine) | post-v1 |
| 4 | `qseries_phylo_q6_planned` | biv_gaussian · phylo · q6 | same as #3 | high (engine) | post-v1 |
| 5 | `qseries_relmat_q6_planned` | biv_gaussian · relmat · q6 | same as #3 | high (engine) | post-v1 |
| 6 | `qseries_spatial_q6_planned` | biv_gaussian · spatial · q6 | same as #3 | high (engine) | post-v1 |
| 7 | `qseries_animal_q8_planned` | biv_gaussian · animal · q8 mu1+mu2+sigma1+sigma2 labelled-slope-covariance | q8 labelled slope covariance; **explicitly barred by the no-q4/q8 promotion rule** | highest + policy-barred | post-v1 |
| 8 | `qseries_phylo_q8_planned` | biv_gaussian · phylo · q8 | same as #7 | highest + policy-barred | post-v1 |
| 9 | `qseries_relmat_q8_planned` | biv_gaussian · relmat · q8 | same as #7 | highest + policy-barred | post-v1 |
| 10 | `qseries_spatial_q8_planned` | biv_gaussian · spatial · q8 | same as #7 | highest + policy-barred | post-v1 |

Rejected alternatives:

- Do not promote any q8 row (7-10): barred by the no-q4/q8 rule; a rejection-
  boundary that *counts* q8 toward the practical surface would itself be q8
  movement.
- Do not attempt a "narrow implementation gate" for the q6 rows (3-6) in this
  arc: that is real multi-slope covariance engine/parser work (Codex lane) plus
  a Rose/Fisher/Grace review gate — not cheap or deterministic.
- Do not implement the simultaneous count-mu row (1) or the broad non-Gaussian
  structured-slope row (2): the 2026-07-05 economy plan already established the
  count-mu blocker is design, not compute ("when the blocker is design, extra
  compute is waste").
- Do not run local, Totoro, or DRAC compute for any of the 10: all blockers are
  design/engine, not missing compute.
- Declined to bump `docs/dev-log/dashboard/status.json`'s `updated` timestamp
  (Grace flagged it as stale). The 07-05 status.json diff was wording-only and
  this session did not re-verify its board metrics, so refreshing the timestamp
  would falsely imply a content refresh. Leaving it is the honest call.

## 3b. Mathematical Contract

No new likelihood, covariance, or parameter-transform contract. The triage is a
planning constraint over existing `planned`/`unsupported` cells. Each row's
prior contract is recorded in `docs/design/216`/`218` and the candidate-review
sidecar; none is delivered here.

## 4. Files Touched

- `.github/workflows/R-CMD-check.yaml` (CI matrix trim; commit `0ce8b919`)
- `docs/dev-log/after-task/2026-07-05-q-series-v1-last-ten-triage.md` (this file)
- `docs/dev-log/check-log.md` (session entry)
- `docs/dev-log/handover/2026-07-05-claude-takeover-day1-handover.md` (fresh next arc;
  the prior Codex→Claude handover is preserved unchanged)
- `AGENTS.md` (prepended the dated "Latest handover — start here" snapshot pointer)

No `R/`, `src/`, `tests/`, dashboard support-cell, or ledger file changed.

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py
  tools/qseries_v1_release_check.py tools/qseries_v1_claim_guard.py`: passed.
- `python3 tools/qseries_v1_release_check.py --summary`: `qseries_v1_release_check_ok`;
  `practical_v1_surface=94/104 (90.4%)`; `exact_inference_ready=8/104`;
  `supported_authority=0/104`; `post_v1=10/104`; `rows_to_90=0`; `rows_to_100=10`.
- `rg` for stale `91/104` / `87.5%` / old rejection wording across README/ROADMAP/
  NEWS/docs/tools/tests: no hits in active surfaces (only dated dev-log records).
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/R-CMD-check.yaml'))"`:
  valid; jobs `os-matrix`, `R-CMD-check`.
- CI PR run: `os-matrix` success → emitted ubuntu-only matrix; `ubuntu-latest
  (release)` leg started (no macOS/Windows leg). See §10 for green confirmation.

## 6. Tests of the Tests

The candidate-review sidecar `q-series-v1-next-candidate-review.tsv` (10 rows)
is validated by `--check-candidates` and the conversion-contract test; the triage
here reads that checked-in ledger rather than re-deriving row identity. The
economy-plan sidecar independently records the count-mu design blocker.

## 7a. Issue Ledger

No GitHub issue opened, commented, or closed. Draft PR #730 opened
(`drmtmb/fix-family-conventions` → `main`); it is the tracking surface for this
practical-v1 checkpoint.

## 8. Consistency Audit

- **Rose (claim language):** no boundary violations in any active user-facing or
  generated file; all agree with 94/104 / 8/104 / 0/104 / 10/104. Residual
  `91/104` strings live only in dated, append-only dev-log/handover records
  (historically correct, superseded). PR body safe when drawn from the ledger.
- **Fisher (inference boundary):** independently recounted `inference_ready` = 8
  rows; the 3 recovered q2 scale-only rows are `point_fit`/`extractor_ready`,
  none promoted. No coverage/rho-interval/REML claim leaked. 8/104 defensible.
- **Ada (integration):** branch is a coherent single-theme checkpoint; land as
  one draft PR; nothing to reconcile before draft. Pre-merge debt: full local
  `check()`/pkgdown.
- **Grace (CI/repro):** Mission Control gates deterministic, R-free/Julia-free/
  network-free; Julia required nowhere. Compiled `src/drmTMB.cpp`+`src/drm_numeric.h`
  changed ~590 lines → cross-OS matters; run the 3-OS matrix once via
  `workflow_dispatch` before ready-for-review.

## 9. What Did Not Go Smoothly

The temptation was to force one of the 10 rows to reach 95/104. Each candidate
that looked cheapest (the count-mu row) has a documented engine-design blocker,
and the q8 rows are policy-barred outright. Forcing any of them would have
crossed a claim boundary or produced non-deterministic engine work — exactly the
"old all-inference campaign" the handover warns against.

## 10. Known Residuals

- Practical surface stays `94/104`; the 10 post-v1 rows are documented above with
  blocker class and cost. None is economical for this v1 lane.
- Pre-ready-for-review gate (not run this session): a full local
  `rcmdcheck::rcmdcheck(args = "--as-cran")` + `pkgdown::build_site()` on the Mac,
  and one 3-OS `workflow_dispatch` R-CMD-check for the compiled-code change.
  This is the Codex live-toolchain lane per the handover.
- CI: the ubuntu-only PR R-CMD-check run for `0ce8b919` — confirm green on #730
  before marking ready-for-review.

## 11. Team Learning

The last 10 rows were never a v1 lane; they are q6/q8 high-q Gaussian and
non-Gaussian family-design gaps whose blockers are design and engine, not
compute. The economical v1 boundary is `94/104` practical, `8/104` inference,
`0/104` supported. The next drmTMB v1 gate is package polish (local
`--as-cran` + pkgdown + one 3-OS CI run), then the merge/split decision on #730
— not another row-promotion push, and not Julia.
