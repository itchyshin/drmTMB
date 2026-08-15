# After-task — drmTMB interval-claim truth audit

**Lane:** `claude/lane-interval-truth-audit` · **Platform:** Claude Code · **Date:** 2026-08-15
**Worktree:** `~/local-scratch/lanes/drmTMB-interval-truth-audit` · rebased onto `origin/main`

## 1. Goal

Give every drmTMB capability cell claiming `evidence_tier` of `interval_feasible` or above a
machine-checked verdict on whether its profile interval actually **brackets its true value**, rather
than merely having the right *shape* (conf_status, convergence, pdHess, boundary, clamp, trace).
237 cells made that claim; only 27 were covered by `tools/profile-truth-manifest.tsv`, the manifest
behind `tools/profile_truth_gate.py` — the one instrument that checks interval **location**.

## 2. Implemented

- **Classified all 210 uncovered cells** as (a) genuinely unchecked = 124, (b) checked by a stronger
  instrument = 21, (c) legacy import with no run = 65. → `2026-08-15-interval-truth-coverage-map.md`
- **Re-checked the 116 re-checkable cells.** Truth was recovered from 101 frozen campaign contracts
  across refs (only 1 survived on `origin/main`). 85 checked: **78 PASS, 7 FAIL**; 31 have no
  recoverable truth and therefore **no verdict**. → `2026-08-15-interval-truth-recheck-verdicts.md`
- **Diagnosed the 7 failures to one mechanism** and compared drmTMB against sdmTMB and INLA.
  → `2026-08-15-spatial-range-drmTMB-vs-sdmTMB-vs-INLA.md`
- **Recovered 134 off-mainline files** (32 runners/adapters, 97 contracts/target maps, 4 md, 1 txt),
  byte-verified. → `2026-08-15-runner-provenance-recovery.md`
- **Narrowed all 28 spatial interval claims** to state the fixed-range conditioning, then extended a
  tier-neutral variant to the 23 fitted spatial cells below those tiers. **All 51 fitted spatial cells
  now disclose;** the 50 that do not are `rejected_by_design`/`not_implemented` and never fit.
- **Demoted the 7** `interval_feasible` → `diagnostic_only`, with 7 `transitions.tsv` rows.
- **Fixed two evidence-ladder inversions** in `tools/capability_ledger.py` and added the guard.
- **Scoped the 73 "re-run" cells** as a construction programme, not a compute job. NOT started.
  → `2026-08-15-rerun-73-scoping.md`

## 3a. Decisions and Rejected Alternatives

| Decision | Rejected alternative | Why |
| --- | --- | --- |
| `legacy_fit_supported` as a new rung below `interval_feasible`; `supported` keeps the summit | Re-tier the 4 cells only; or fix the aggregates and keep one token | Owner chose "separate the token". Renaming makes every aggregate honest at once and matches what the reader translator already said; re-tiering alone leaves the token ambiguous for the next import. |
| The 7 demoted to `diagnostic_only` | `point_fit_recovery` (the Arc-7b precedent) | That precedent rested on *"the point-fit gate it passed before profiling is unaffected"*. These cells have no such gate — their only non-legacy evidence records receipt SHAPE — and the same fixture misspecification means the point estimate was never validly tested either. `point_fit_recovery` would over-claim. |
| Narrow the spatial claims, do not repair-and-re-promote | Repair the fixture and re-promote | The repair was written and validated for alignment (rel 1.7e-14), but the repaired fit reported `singular convergence (7)` and still carried 25–52% error on 3 of 4 targets. Removing a misspecification changes the diagnosis; it does not earn the claim back. |
| No mesh conditioning sentence | Draft one for the mesh route | Adversarial review: zero ledger cells are mesh-routed, and `R/check.R:2977-2982` withholds mesh intervals entirely. A qualifier would have **asserted a claim the package denies**. |
| Truth derived from frozen contracts | Read `true_value` from receipts, or from `claim_boundary` prose | No committed receipt carries `true_value`. Three cells state their true SD in prose; lifting it would recreate this arc's own defect one layer up. |
| The 73 not started | Fold a re-run campaign into this arc | 0 of 73 have a contract or a profile runner — there is no truth to check against. It is fixture construction (~40–70 h), not compute. |

## 4. Files Touched

**Created — dev-log**
`docs/dev-log/2026-08-15-truth-gate-extension-points.md` ·
`docs/dev-log/2026-08-15-interval-truth-coverage-map.md` ·
`docs/dev-log/2026-08-15-interval-truth-recheck-verdicts.md` ·
`docs/dev-log/2026-08-15-spatial-range-drmTMB-vs-sdmTMB-vs-INLA.md` ·
`docs/dev-log/2026-08-15-runner-provenance-recovery.md` ·
`docs/dev-log/2026-08-15-rerun-73-scoping.md` ·
`docs/dev-log/2026-08-15-supported-tier-claims-question.md` ·
this report · `docs/dev-log/plan-actual/2026-08-15-interval-claim-truth-audit.md`

**Modified — tools and ledger**
`tools/capability_ledger.py` (EVIDENCE_TIERS, TIER_ORDER, widget tiers, reader translator, both
evidence summary lines, ladder prose) ·
`tools/tests/test_capability_ledger.py` (1 test moved to the new token, 3 added) ·
`docs/dev-log/dashboard/capability-ledger/cells.tsv` (51 boundaries narrowed, 4 re-tiered, 7 demoted)
· `docs/dev-log/dashboard/capability-ledger/transitions.tsv` (+11 rows) ·
`docs/dev-log/dashboard/capability-ledger/schema.json` (enum) · 31 regenerated outputs

**Recovered — 134 files** under `tools/` and `docs/dev-log/interval-campaign-bindings/`; manifest with
source commits at `scratchpad/recovery-result.json`

**LOOP kit** `LOOP/{GOAL,arcs,checkpoint,ultra-plan}.md` · **scratchpad** cohort/census/verdict JSON+TSV
and `scratchpad/recover/q4-spatial-fixture-repair.R`

## 5. Checks Run

| Check | Result |
| --- | --- |
| `python3 tools/capability_ledger.py --check` | **OK (31 generated outputs)** |
| `python3 -B tools/tests/test_capability_ledger.py` | **76/76 OK** (was 73 at lane start) |
| `python3 -B tools/tests/test_profile_truth_gate.py` | **24/24 OK** |
| Post-rebase re-run of all three | **green** on top of `origin/main` `9f1ea65ba` |
| `pkgbuild::compile_dll()` | exit 0, `src/drmTMB.so` 29 MB |
| Repaired-fixture alignment assertion | precision rel diff **1.673e-14** vs the model's own |
| One repaired q4 fit | 7.5 s, `convergence=1 (singular convergence (7))`, pdHess TRUE |

**Not run:** `devtools::check()` / `--as-cran` / `pkgdown` — no R package source changed (`R/`, `src/`,
`NAMESPACE`, `DESCRIPTION` untouched). The R-side change is data and tooling only.

## 6. Tests of the Tests

- **`test_tier_order_is_monotone_in_reader_permission` was proven by making it fail on purpose.** Run
  against the pre-fix order it reports `INVERSIONS -> diagnostic_only < point_fit_recovery`; against
  the fixed order, `MONOTONE`. It would have caught **both** inversions.
- **Two existing tests caught my changes, correctly, and both were strengthened rather than relaxed.**
  `test_legacy_supported_label_does_not_authorize_an_interval` failed on the token split and moved to
  the new token; `test_student_structured_tiers_fail_closed_to_live_ledger` failed on the `mc-0494`
  demotion and now pins `diagnostic_only` **and** the conditioning sentence, so the justification is
  pinned, not just the value.
- **The claim-boundary edit path was proven empirically before use**, not read off the code: a probe
  string was injected into one cell, `--write` run, the probe confirmed to survive in `cells.tsv` and
  to propagate to `capability-surface.html` / `_master.tsv`, then reverted.
- **Recovery was verified four ways** — two recovered files hash to digests recorded *inside* the
  contracts (byte-exact); `source_map_sha256` 12/12 MATCH; 32/32 recovered R files `parse()`; gates
  unchanged.

## 7a. Issue Ledger

| # | Issue | State |
| --- | --- | --- |
| 1 | `supported` was one token for the ladder summit and a legacy fit label | **FIXED** |
| 2 | `diagnostic_only` ranked above `point_fit_recovery` while authorizing less | **FIXED** |
| 3 | 7 spatial cells' interval claims not supported by their own fixture truth | **DEMOTED** |
| 4 | 28 spatial claims silent on the fixed-range conditioning | **FIXED** |
| 5 | `mc-0285` boundary asserted mesh "planned but not implemented (R/drmTMB.R:8434-8440)" — false on both halves | **FIXED** |
| 6 | 96/116 cells' runners and 100/101 contracts off-mainline | **RECOVERED** |
| 7 | `binding_source_sha256` does not hash `binding_source` (one value for 7 paths) | **RECORDED, not fixed** |
| 8 | 31 re-checkable cells have no recoverable truth | **OPEN** |
| 9 | 73 cells need fixture+contract construction (~40–70 h) | **SCOPED, not started** |
| 10 | 5 `association` cells (`two_stage_Godambe`) outside the gate's domain | **OPEN** |
| 11 | 8 cells name no runner at all | **OPEN** |
| 12 | 23 sub-interval-tier spatial cells share the conditioning, undisclosed | **FIXED** — every fitted spatial cell now discloses |
| 13 | `mc-0596`: `verified` here vs "false convergence (8)" in the landed response-mask arc | **OPEN — D-87, owner's call** |
| 14 | `q-series-v1-release-status.md` stale, linked from `README.md:75` | **OPEN** |
| 15 | `lane_preflight.sh` line 379 arithmetic error; census omitted 2 cursor lanes | **OPEN — reported to its owner** |

## 8. Consistency Audit

**Fix the class, not the instance** — applied three times:

- Finding one ladder inversion (`supported`) prompted a check of the adjacent pair, which found the
  second (`diagnostic_only`/`point_fit_recovery`). The guard added covers **the whole ladder**, not
  the two pairs I happened to walk into.
- Finding one cell whose truth was joined on the wrong key (`mc-0248`) prompted a re-run of **all 85**
  comparisons under strict `target_id` matching. Only 2 of 85 carried multiple targets, so the blast
  radius was small — but it was measured, not assumed.
- The spatial mechanism was checked against the **whole provider**: 28 cells at interval tiers were
  swept, and the 23 below those tiers that share the mechanism were enumerated and recorded as open
  rather than silently excluded.

**Neighbourhood walked:** `validate-mission-control.py` and `qseries_v1_release_ledger.py` also use the
token `supported`, for `fit_status` / `authority_status` / `coverage_status` — **different columns,
deliberately untouched**. All 15 refs touching `test_capability_ledger.py` were checked before editing
to confirm no other lane carries the same fix (none does).

**Memory receipt:** loaded the repo `AGENTS.md` LOAD-FIRST manifest, `CLAUDE.md`, and the hub
`AGENTS.md`. **Golden Set:** not in scope — this arc changed no R package source (`R/`, `src/`,
`NAMESPACE`, `DESCRIPTION` untouched), so no known-mistake class in `tools/memory_regression.py`'s
domain was in play; the lane's own regression surface is the ledger/gate test suites, run after every
step and re-run post-rebase. Guards
that actually shaped the work: **D-139** (estimate before running — produced the 73-cell scoping and
the pre-run measurement), **D-88/D-87** (lane boundaries — no foreign file touched; `mc-0596` surfaced
rather than resolved), **D-50** (no campaign on Actions), **D-43** (completion claims), the Arc-7b
demotion-wording rule, and *"a narrow or negative search is not proof"* — which fired four separate
times (a truncated `head -40`, a wrong-bracket regex, `grep -c` counting lines not matches, and a
single-tree receipt census). `/ask-brain` was run **before** writing lessons; two relevant priors were
found and the new lesson was filed as their *complement*, not a duplicate.

## 9. What Did Not Go Smoothly

- **I reported a confident, specific, wrong number.** `mc-0248` was published as a 99% failure with a
  mechanism note saying it was unexplained. It was my join error — truth matched against a target the
  cell's own boundary excludes. The audit built to catch unchecked claims produced exactly that defect
  one layer up. Corrected with a dated CORRECTION block rather than a silent rewrite.
- **Four negative searches were wrong.** `ls | grep | head -40` truncated away the runners I then
  called missing; a regex found "0 pinned cells" when 8 were pinned; `grep -c` counted lines and
  undercounted disclosures 2 vs 56; and the first receipt census read one of two receipt trees.
- **The first wording draft was unusable.** Adversarial review (3 lenses, all `PROBLEMS_FOUND`) showed
  the mesh sentence would have asserted a claim the package denies, and that the sharper disclosure was
  about the *evidence* never varying the range, not about the code fixing it.
- **The worktree had no compiled DLL**, and the main checkout's `.so` was built from different C++ — so
  it could not be borrowed without violating "loaded namespace == checkout". A ~20 min compile.

## 10. Known Residuals

- **121 of 233 claiming cells still have no location check.** The arc moved coverage 27 → 112.
- **31 re-checkable cells have no verdict** — no recoverable truth. Not a pass.
- **The 78 passes are magnitude-only for 110 of 116**: at one retained seed the gate's count arm is
  structurally unreachable (`1 > 1` is False, `profile_truth_gate.py:221`). A PASS means *no single
  interval missed truth by more than 5% of scale* — weaker than the 3–5-seed standard.
- **The 78 passes rest on frozen contracts.** Contract-matches-code was *proven* for the q4 cohort
  only, not re-established per campaign.
- **116 re-checks rest on 105 independent runs** — 13 `animal`↔`relmat` pairs share bit-identical
  intervals (expected equivalence, not a defect, but a published table must not imply 116).
- **Recovery is not re-execution.** 134 files parse; none was run. Two known blockers stand: the
  `runner_sha256` mismatch on `mc-0421/0423/0424`, and `mc-0423`'s `n_founders = 4` vs current `8`.
- **sdmTMB/INLA were not run** — neither is installed. The comparison rests on their documentation.
- **The repaired spatial fixture is not promotable**: one seed, `singular convergence (7)`, 25–52%
  error on 3 of 4 targets.
- Issue-ledger rows 7–15 above remain open.

## 11. Team Learning

Three lessons filed to `~/shinichi-brain/memory/LESSONS.md` (commit `7a26ebc`):

1. **The unit of a check must be the unit of the CLAIM.** A cell is not the unit of a location check —
   a *target* is. Join on the claim's own key; never silently substitute on a non-match. The fallback
   *was* the defect: without it the mismatch would have surfaced as "no truth for this target", a true
   statement. Recorded as the **complement** of the existing *"suspect the spot-check"* lesson —
   there the detector was right; here the detector was wrong, because it joined on a coarser key.
2. **Evidence can be real, recoverable, and still not reproducible from the mainline.** "Not in the
   checkout" ≠ "never existed": ask `git log --all` and check ancestry before concluding.
3. **drmTMB fixes the spatial range where sdmTMB and INLA estimate it** — so the SD absorbs range
   misspecification. Plus the repair caution: removing a misspecification changes the diagnosis without
   earning the claim back.

For this repo specifically: **rank and permission must be compared by a test, not by a reader.** Both
ladder inversions survived because the two lived in different functions.

## 12. Cross-Product Coverage

**Cross-cutting thing #1 — the `evidence_tier` ladder** (touches every cell, every aggregate, every
reader surface).

Covers ✓ — `TIER_ORDER` ranking · `EVIDENCE_TIERS` enum · `schema.json` enum · `reader_reporting_permissions`
for all 8 tiers · both evidence summary lines · the widget tier matrix · the dashboard ladder prose ·
the family-map "highest tier" · monotonicity of rank vs permission, now test-pinned.

It does NOT cover ✗ — `validate-mission-control.py`'s `fit_status`/`authority_status`/`coverage_status`
vocabularies (different columns, same token, deliberately untouched) · `qseries_v1_release_ledger.py`'s
`authority_status` · whether tiers *other than* the two pairs examined carry further semantic collisions
(only `supported` was traced through every use) · the `G0–G5` gate vocabulary on the missing-response
axis · any downstream consumer of `cells.tsv` outside this repo.

**Cross-cutting thing #2 — the `spatial` provider's fixed range** (touches every spatial claim in the
package).

Covers ✓ — all 28 spatial cells at interval tiers, disclosure applied and verified in
`capability-surface.html` and `_master.tsv` · the `coords` route mechanism, cited to
`R/drmTMB.R:13403-13407` including the `max()` fallback · the 7 cells whose fixture truth is not the
model's estimand, demoted · `mc-0285`'s false mesh statement, repaired.

Covers ✓ (added after the first close) — the **23 spatial cells at `diagnostic_only` /
`point_fit_recovery`**, given a tier-neutral variant of the sentence ("the spatial sd(group) *estimate*
here is conditional on…", since these carry no interval claim). **All 51 fitted spatial cells now
disclose.** Mesh was ruled out for all 23 structurally, not assumed: `allow_mesh = TRUE` occurs once,
on the univariate-Gaussian-`mu` route, and none of the 23 sits on it.

It does NOT cover ✗ — the **mesh/SPDE route**, whose kappa is equally fixed and which has *no* ledger cell and no interval claim
to qualify · the 50 non-fitted spatial rows (48 `rejected_by_design`, 2 `not_implemented` — no fit, nothing to
condition) · whether
`spatial()` *should* estimate its range (a design question, not settled here) · any non-spatial
provider — `phylo`, `animal`, `relmat`, `phylo_interaction` were **not** audited for an analogous
fixed-hyperparameter conditioning, and the `animal`/`relmat` arms passing here says nothing about
whether *their* claims disclose their own assumptions.
