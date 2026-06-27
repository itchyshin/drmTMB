# After-task: count-structured-mu rejection contract (6 boundary cells)

Meta: 2026-06-27 · Claude (ultracode) session · branch
`claude/count-structured-mu-rejection-contract` · q-series structured-RE completion lane.

## 1. Goal

Bank the exact pre-optimization rejection boundaries for structured count `mu`
routes the engine already rejects but that were only documented as prose inside
neighbour cells' claim_boundaries — surfaced by a comprehensive 145-sidecar
consolidation sweep whose adversarial refuter found them. Same class as the
banked #676 (count sigma) and #678 (non-Gaussian family) contracts. No support
is promoted; every new cell stays `unsupported`.

## 2. Implemented

- New sidecar
  `docs/dev-log/dashboard/structured-re-count-structured-mu-rejection-contract.tsv`
  with **6 rows**, one per engine gate (all `pre_optimization_formula_gate`):
  1. non-canonical/slope-only structured count `mu` coefficient
     (`"intercept-only or one-slope"`, Poisson/spatial)
  2. labelled q=2 structured count `mu` (`"unlabelled q=1"`, Poisson/spatial)
  3. structured + ordinary combined (`"cannot be combined"`, Poisson/spatial)
  4. zero-inflated Poisson structured `mu`
     (`"Zero-inflated Poisson structured random effects"`)
  5. zero-inflated NB2 structured `mu`
     (`"Zero-inflated NB2 structured random effects"`)
  6. simultaneous structured effect types (`"Only one structured"`, NB2)
- 6 new `unsupported` rows in
  `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
  (q-series cells **98 → 104**), `family_class = non_gaussian`, all status
  columns `unsupported`, `denominator_policy = no_denominator_until_fit`.
- Validator registration in `tools/validate-mission-control.py`: path constant,
  `read_tsv`, fields schema, a per-row validation block (mirrors the #678
  nongaussian block: row count, schema, support-cell linkage with all-unsupported
  statuses, exact per-cell `expected_error_pattern`, claim-boundary disclaimers),
  and a summary count line.

## 3a. Decisions and Rejected Alternatives

- **Each cell records its REAL engine message** (e.g. `"cannot be combined"`,
  `"Only one structured"`), not the shared `"Structured non-Gaussian paths"`
  string — these are distinct count-`mu` formula gates
  (`validate_count_structured_mu_term`, `select_count_mu_structured_term`,
  `validate_poisson_mu_random_terms` in `R/drmTMB.R:6772-6881`).
- **Cited the EXISTING test** `tests/testthat/test-count-structured-mu.R`
  (the `"count structured mu keeps planned neighboring routes closed"` block,
  lines 391-465 already `expect_error` each boundary) — **no new brittle
  message-anchor test was added**, deliberately minimizing the message-substring
  fragility the handover flagged (item 5).
- **Excluded the test's 7th `expect_error`** (line 454-463, structured *sigma* →
  `"Structured non-Gaussian paths"`): that is a scale-side / non-Gaussian-paths
  boundary already covered by #676/#678, not a count-`mu` cell.
- **`structure_provider = spatial`** for the simultaneous-types cell (the global
  validator rejects a `multiple` provider value); the two-provider nature is
  carried by `formula_cell` (`spatial(...) + relmat(...)`) and the boundary text.
- Verified each gate + message + test line from source before banking (the #678
  lesson: a subagent contract can be wording-inaccurate; this one was checked).

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-count-structured-mu-rejection-contract.tsv` (new)
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv` (+6 rows)
- `tools/validate-mission-control.py`
- `docs/dev-log/after-task/2026-06-27-count-structured-mu-rejection-contract.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- **No live R / `devtools` / `testthat` run this session** (unavailable; the
  cited tests are pre-existing). Engine gates + messages confirmed by reading
  `R/drmTMB.R:6772-6881` and `tests/testthat/test-count-structured-mu.R:391-465`.
- `python3 -m py_compile tools/validate-mission-control.py`: OK.
- `python3 tools/validate-mission-control.py`: `mission_control_ok`, **104**
  q-series cells, **6** count structured-mu rejection rows.
- `git diff --check`: clean.
- Provenance: the boundaries were independently surfaced by the consolidation
  sweep's refuter, then source-verified here before banking.

## 6. Tests of the Tests

- Each `expected_error_pattern` is the literal substring the existing
  `expect_error` in `test-count-structured-mu.R` matches against, so the contract
  and the test agree by construction.
- The validator cross-checks each contract row against its support-cell row,
  forbidding a rejection cell that silently implies any support
  (fit/extractor/bridge/interval/coverage must all be `unsupported`).

## 7a. Issue Ledger

- Fixed: the global `structure_provider` enum rejected `multiple`; the
  simultaneous-types cell now uses `spatial` with both providers named in the
  formula.
- Carried forward: these contracts share the **message-substring fragility**
  flagged in handover item 5 (rewording an engine `cli_abort` line could drift
  the `expected_error_pattern`). Mitigated by reusing existing tests, not adding
  new anchors; the item-5 maintainer decision (anchor on an error class instead
  of a message substring) would apply to these too.

## 8. Consistency Audit

- 6 contract rows ↔ 6 support-cell rows ↔ 6 validator dict entries, all linked
  by `cell_id`; validator green confirms the linkage.
- All new cells `unsupported` across the full ladder; no `coverage_status` moved.
- Mirrors the #676/#678 rejection-contract shape exactly (same fields, same
  pre-optimization-gate framing).

## 9. What Did Not Go Smoothly

- First wide consolidation sweep (14 agents) tripped a provider rate limit;
  re-run in waves of ~4, after which all 145 sidecars verified clean and the
  refuter surfaced these cells.

## 10. Known Residuals

- These cells remain `unsupported`; they document boundaries, they do not move
  the plan toward `supported`. The decisive rungs (coverage/intervals/bridge)
  stay externally gated.
- A live `devtools::test(filter = "count-structured-mu")` by Codex would confirm
  the cited `expect_error` block still passes against the current engine (it was
  not run this session).

## 11. Team Learning

A comprehensive adversarial sweep earns its cost not by re-confirming what is
clean (all 145 sidecars were) but by refuting the operator's own "nothing left"
claim: the refuter found five-plus genuinely advanceable boundary cells hiding as
prose inside neighbour cells. The exact-cell discipline means a boundary that is
only *described* in another cell's disclaimer is not yet *banked* as its own cell
— and banking it is real, guard-clean, no-live-R plan progress.
