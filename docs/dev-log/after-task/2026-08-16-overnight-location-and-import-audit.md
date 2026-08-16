# After-task — overnight: location verdicts, the 44-cell import audit, and four residuals closed

**Lane:** `claude/lane-overnight-0815` · **Platform:** Claude Code · **Date:** 2026-08-15/16
**Delegation:** owner handed the session unattended until 05:00 with "do as much as possible".

## 1. Goal

Convert the open residuals left by the day's two merged PRs into either closed items or recorded
facts, without spending Mac CPU, without merging anything risky, and without taking the two decisions
the owner reserved (the 44-cell claims call and `mc-0596`).

## 2. Implemented

- **A3 — 31/31 truth recovered and location-checked, zero compute.** All 31 cells with a retained
  receipt but no recoverable truth now have both. **31/31 pass, every interval brackets, worst miss
  0.0%.** `location_checked` `unchecked → passed`. Claiming totals: **176 passed / 44 unchecked /
  6 not_applicable**.
- **A2 — the 44-cell import audited** against the newly-decided shape contract: **19 shape-justified,
  22 that never compute an interval at all, 3 with an unwired campaign whose coverage is 0.81–0.86**.
  Facts only; no tier touched.
- **A1 — `location_checked` rendered**: census column, derived sentence on the reader summary, the
  surface markdown and the surface HTML; pinned by a new test.
- **A4 — staleness sweep**: the sr475 defect has **8 siblings**, all from one 2026-06-30 commit; the
  supersession note now covers all nine. The negative half is recorded too — 190 decision-bearing
  TSVs checked, the class did not recur elsewhere.
- **A5 — the 3 flagged vacuous-shape sites are all real.** Residual closed with zero fixes.
- **A6 — `binding_source_sha256`**: the validator enforces coherent semantics (it hashes the shared
  bindings input, not the per-row source). My earlier "not a provenance guarantee" claim was wrong and
  is corrected; semantics documented in a new README.
- **A7 — `mc-0596`**: the cross-arc tension is a **fixture difference, not a contradiction**. Three
  seeds of the fixture backing the interval claim: outer convergence 0, pdHess TRUE, and an
  independent `nlminb` restart re-confirms the optimum under both the raw defaults and the campaign's
  900-iteration budget. Facts only; D-87 disposition remains the owner's.

## 3a. Decisions and Rejected Alternatives

| Decision | Rejected | Why |
| --- | --- | --- |
| `mc-0282` truth = 0.6 | the contract's 0.55 | that DGP has **no receipt anywhere** — never executed. 0.6 matches the receipt on disk and is independently corroborated by the `UNGATED` exemption's own hand-check. |
| Record the 22 (C) cells; do not demote | demote to `diagnostic_only` | a 22-cell tier change is a claims decision the owner reserved. Facts assembled instead. |
| Revert the zero_one_beta assertion fix | keep it and re-pin `mc-0568`'s receipt | the file is source-bound evidence for a retained receipt; re-pinning is a provenance decision, not a test improvement. |
| Do **not** wire the student campaign | wire it as (A) evidence | its coverage is 0.81–0.86 vs nominal 0.95 — wiring would justify `failed`, not `passed`. Needs its own review. |
| Agents cloud-side, local = grep/git/python | run the audits locally | the owner asked for CPU restraint mid-session. |

## 4. Files Touched

`tools/capability_ledger.py` (rendering + `location_summary_line`) · `tools/tests/test_capability_ledger.py`
(+1 test) · `tools/integrate_b4_ci_c1.py` (3rd gated re-freeze) · `cells.tsv` (31 `location_checked`
promotions, 8 citation repairs) · 31 regenerated outputs · new docs:
`2026-08-15-location-verdicts-31.md`, `2026-08-15-import-44-shape-audit.md`,
`interval-campaign-bindings/README.md`, extended `2026-08-15-sr475-results-supersession.md`,
this report + plan-actual + check-log · `scratchpad/overnight-*.md` (7 agent reports).

## 5. Checks Run

| Check | Result |
| --- | --- |
| `capability_ledger.py --check` | **OK (31 outputs)** after every change |
| `test_capability_ledger` / `test_b4_ci_c1` / `test_profile_truth_gate` | **OK** |
| `test-zero-one-beta.R` (during the attempted fix) | FAIL=0, 1521 passes |
| mutation proof on the new assertion | mutant **FAIL=1**, revert **FAIL=0** |
| `mc-0596` diagnostic (3 fits, single-threaded) | conv=0, pdHess TRUE, grad-max ≤ 1.2e-3 |
| location check, 31 cells | 31/31 pass, 100% bracketing |

## 6. Tests of the Tests

The new `test_location_checked_is_rendered_and_derived` **failed on first write** — the census column
had rendered but the summary line had not reached the HTML — which is the test doing its job before
the feature was complete. The zero_one_beta assertion was mutation-proven red before being reverted
for an unrelated provenance reason, so its correctness is established even though it did not land.

## 7a. Issue Ledger

| # | Issue | State |
| --- | --- | --- |
| 1 | 31 cells with receipts but no truth | **CLOSED** — recovered + checked, all pass |
| 2 | `location_checked` stored but unrendered | **CLOSED** |
| 3 | 3 vacuous-shape test sites | **CLOSED** — all real |
| 4 | `binding_source_sha256` "not a guarantee" | **CLOSED** — my claim was wrong; documented |
| 5 | `mc-0596` cross-arc tension | **RESOLVED AS FACTS** — fixture difference; decision reserved |
| 6 | frozen-before-decision staleness | **CLOSED** — 9 files covered, class swept repo-wide |
| 7 | 44-cell import disposition | **OPEN — owner's call**, facts in the audit doc |
| 8 | student campaign 0.81–0.86 coverage, unwired | **OPEN** — needs its own review |
| 9 | 22 (C) cells; option-2 fix blocked where the test is blob-pinned | **OPEN** |
| 10 | PSOCK worker leak in `drmTMB(se = TRUE)` | **OPEN** — spawned as its own task |

## 8. Consistency Audit

Two citation errors **of my own from earlier today** were found by this audit and repaired: an
over-reaching range extension that made `mc-0486` look shape-justified using a *different* test's
assertions, and an off-by-one that left `mc-0623/0625/0627` citing 100 when their assertions sit at
101-103. Both were introduced by the same mechanical line-shift, so the whole shift was re-examined.

**Memory receipt:** loaded repo `AGENTS.md` LOAD-FIRST, `CLAUDE.md`, hub `AGENTS.md`. Guards that
fired: D-88/D-87 (lane named; `mc-0596` and the 44-cell call surfaced, not taken), D-139 (no campaign;
the only compute was 3 single fits), D-50, append-only corrections, and today's own twice-learned
lesson — a blank field is not evidence of absence — which is precisely what the 31-cell recovery
exploited. **Golden Set:** not in scope; no R package source changed.

## 9. What Did Not Go Smoothly

- I introduced two citation errors earlier in the day and only found them because independent agents
  re-read the same cells. Mechanical line-shifts across cited ranges are more dangerous than they look.
- The zero_one_beta fix was written, tested, mutation-proven, and then thrown away — the right call,
  but an hour spent discovering a coupling I should have checked first (is this test blob-pinned?).
- `31/31 pass` looked too clean; scrutinising it was the correct instinct even though it held up.

## 10. Known Residuals

Issues 7–10 above. Plus: 26 of the 31 location verdicts are **magnitude-only** (single seed); the 44
unchecked cells are exactly the import; `mc-0300`/`mc-0312` truths rest on a frozen contract value
alone; and the option-2 partition (which of the 22 are blob-pinned) has not been computed.

## 11. Team Learning

**A blank or code-shaped field in the current ledger is not evidence of absence — it is usually a
migration that dropped a link.** Applied deliberately tonight, it converted 31 "unrecoverable" cells
into 31 verdicts with zero compute. The counterpart, equally load-bearing: **an edit to a test file
can break a provenance binding for a completely different cell** — check blob-pinning before touching
a test that a receipt cites.

## 12. Cross-Product Coverage

**Cross-cutting thing — `location_checked` as a rendered, populated field.**

Covers ✓ — all 740 cells populated · 31 new `passed` verdicts derived from recovered truth · rendered
on census HTML, reader summary, surface md and surface HTML · test-pinned for agreement between the
stored column and the rendered line · both B4-CI pins re-frozen under field-level proof.

It does NOT cover ✗ — the 44 import cells (still `unchecked`, disposition reserved) · any *gate* that
consumes the field (the truth gate still keys on tier rank) · coverage as distinct from single-interval
bracketing (26 of 31 are single-seed) · the `missing_response` axis's G-gates, which have their own
ladder · the association axis, marked `not_applicable` by construction and never re-examined tonight ·
automatic population for future cells (the validator rejects unknown values but nothing forces a new
row to declare one).
