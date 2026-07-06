# After Task: M3 q12 cell_id rename + README/ROADMAP capability backfill

Meta: 2026-07-05 · Claude (Shannon) · branch `claude/inspiring-proskuriakova-8818b0`
· follow-up to the M3 q12 admission (after-task
`docs/dev-log/after-task/2026-07-05-m3-q12-all-four-admission.md`, §10). Two tracked
doc/naming-debt items deferred from the admitting change, done together as one PR
because they touch overlapping surfaces.

## 1. Goal

Close the two debts M3 deferred by design so a mechanical rename would not conflate
with the source admission:

- **PART 1 — cell_id rename.** The M3 admission reused the four placeholder keys
  `qseries_<provider>_q8_planned` (provider ∈ phylo/spatial/animal/relmat) for the
  concrete q12 two-slope all-four cell (`dimension_pattern = q12`). Rename them to
  `qseries_<provider>_q12_all_four_two_slope` so the key stops lying about its
  dimension. (The distinct `_q4_all_four_one_slope_planned` q8 one-slope cells are
  **not** touched.)
- **PART 2 — README/ROADMAP capability backfill.** The public capability catalogs
  described the q8 one-slope all-four cell but never the M2 structured q6 two-slope
  location surface or the M3 q12 two-slope all-four surface. Add both, honestly.
- **PART 3 (optional, Rose safeguard #2).** Add a claim-guard check that fails when a
  `dimension_pattern = q12` cell is in the support-cell ledger but absent from the
  README/ROADMAP capability catalogs — the drift class the current gates miss.

## 2. Implemented

- **PART 1 — rename across the 6 live surfaces (25 changed lines / 34 token
  occurrences), no C++/public-API/bridge-key touch.** Blanket
  `_q8_planned` → `_q12_all_four_two_slope` in:
  - `tools/validate-mission-control.py` (8: the `STRUCTURED_RE_REQUIRED_Q_SERIES_CELLS`
    set + the `expected_high_q_widget_states` map; state-preserving —
    `high_q_gate_required` count stays 16).
  - `tests/testthat/test-structured-re-conversion-contracts.R` (4: `required_cells`).
  - `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv` (4 cell_ids —
    the hand-maintained source of truth).
  - `docs/dev-log/dashboard/structured-re-high-q-status-audit.tsv` (12: `audit_id`,
    `cell_id`, and `high_q_scope` per row × 4 rows — renamed together so the audit_id
    `high_q_<provider>_q8_planned` and scope `structured_q8_planned` stop re-creating
    the same q8-on-q12 smell the rename removes).
  - `docs/dev-log/dashboard/structured-re-q-series-closure-triage.tsv` (2: the
    `example_cells` sample, which the validator cross-checks against `q_series_cell_map`).
  - `docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv` (4):
    **regenerated** via `python3 tools/qseries_v1_release_ledger.py --write --write-status`
    (it is derived from support-cells, not hand-edited).
- **PART 2 — capability backfill.** README rows for phylogenetic (270), coordinate
  spatial (271), and animal/relmat (272) structured effects, and the ROADMAP Phase-5
  closure-boundary rows for the same three providers (478/479/480), now list the
  labelled two-slope `(1 + x + z | p | …)` **q=6 `mu1`/`mu2` location** and **q=12
  all-four** point-fit/recovery cells. Each addition keeps the M2/M3 honesty: recovery
  evidence only, derived correlations route through profile/bootstrap, intervals and
  coverage planned; q=12 recovers a known 66-correlation Σ with `pdHess=FALSE` by
  design. Per-provider boundary columns and the "Reserved or planned neighbours"
  summary (README 275) were re-qualified so "multiple phylogenetic/spatial/structured
  slopes … remain planned" now reads "beyond the labelled shared-label two-slope q=6/q=12
  cells" — otherwise the two-slope admission would contradict the flat reserved wording.
  The ordinary-bivariate row (269) already framed ordinary q6 as smoke/diagnostic and
  has no ordinary q12 cell, so it is unchanged.
- **PART 3 — capability-catalog freshness guard.** `tools/qseries_v1_claim_guard.py`
  gains `check_capability_catalog()` (wired into the default `check_claims()` run): for
  each `CATALOG_REQUIRED_DIMENSION_PATTERNS` entry (`q12` today, tuple extensible) that
  appears in the support-cell ledger, README.md and ROADMAP.md must each carry a q12
  capability mention (`q=12`/`q12`, with a trailing boundary so `q=120` does not
  false-match). Teeth verified in isolation (flags a stripped catalog, passes when both
  mention it, inert when no q12 cells exist).

## 3. Verdict

The four q12 keys now name their dimension; the public catalogs describe the q6 and q12
surfaces at their true (point-fit/recovery, intervals/coverage-planned) status; and a new
guard makes future q12 catalog drift fail loudly. No status word was inflated — every
addition is hedged and the guard is negation-safe.

## 4. Files touched (9 tracked)

`README.md`, `ROADMAP.md`, `tools/qseries_v1_claim_guard.py`,
`tools/validate-mission-control.py`,
`tests/testthat/test-structured-re-conversion-contracts.R`, and the four dashboard
TSVs (support-cells, high-q-status-audit, closure-triage, v1-release-ledger). No C++,
no exported R API, no cross-repo bridge key.

Deliberately **not** touched: the distinct `_q4_all_four_one_slope_planned` q8 one-slope
cells; and the dated historical records that mention `_q8_planned` as the pre-rename
state — `docs/dev-log/after-task/2026-07-05-m3-q12-all-four-admission.md`,
`…/2026-07-05-q-series-v1-last-ten-triage.md`,
`docs/dev-log/handover/2026-07-05-claude-m3-q8-determination.md`,
`docs/dev-log/check-log.md`, and `docs/design/218-structured-q-series-completion-map.md`
(under its "Decision executed (2026-07-05)" heading). Rewriting dated decision records
would falsify them; this report is the forward record that the rename is done.

## 5. Checks run (all green)

| Gate | Command | Exit |
|---|---|---|
| mission-control | `python3 tools/validate-mission-control.py` | 0 |
| release ledger | `python3 tools/qseries_v1_release_ledger.py --check --check-status` | 0 |
| claim guard | `python3 tools/qseries_v1_claim_guard.py` | 0 |
| release check | `python3 tools/qseries_v1_release_check.py --check-report --check-candidates` | 0 |

`tests/testthat/test-structured-re-conversion-contracts.R`: **22259 pass / 0 fail / 0
warn / 0 skip** (0 skips confirms it ran against the renamed dashboard data, not a
skipped guard). Mission-control reports the expected shape: 104 q-series cells, 104
release-ledger rows, 24 high-q audit rows, 16 closure-triage rows.

**Worktree-isolation caveat (important).** Gates 1 and 4 embed
`evidence_reference_exists`, which resolves `evidence_url` paths against files on disk.
Some of those live under **gitignored** artifact trees
(`.gitignore` `docs/dev-log/recovery-checkpoints/` and
`docs/dev-log/ayumi-convergence/**/*.csv`) that exist in the main checkout but do not
propagate to a fresh worktree. On the untouched clean tree, gates 1/4 therefore emit the
**identical** 7 Ayumi/SR199/recovery-checkpoint "evidence does not resolve" errors before
**and** after this change (verified by `git stash`), so the rename adds zero new errors.
The exit-0 results above were obtained after mirroring the maintainer environment by
copying the referenced gitignored evidence from the main checkout into the worktree;
those files are gitignored and are **not** part of the change set (`git status` shows 0
untracked, 9 modified).

## 6. Tests of the tests

The rename is state-preserving and cross-checked from three directions: the
support-cells key, the validator's hardcoded `expected_high_q_widget_states` key, and the
closure-triage `example_cells` entry all had to move together or the mission-control
cross-checks (cell-set equality at lines ~27212/27299; example-cell membership at
~19116) would fail — they pass, so the three surfaces agree. The regenerated ledger diff
is exactly its 4 cell_id lines (no reordering). The new guard was checked to both **fail**
(stripped catalog) and **pass** (documented), and to be inert when the ledger has no q12
cell, so it is not a tautology.

## 7. Issue ledger

No GitHub issue. Continues the Q-Series 104/104 arc after the M3 admission
(`docs/dev-log/after-task/2026-07-05-m3-q12-all-four-admission.md`).

## 8. Consistency audit (named lenses)

- **Rose (claims/scope):** the rename hit exactly the 6 live surfaces Rose enumerated
  (25 lines); the 5 dated historical records keep `_q8_planned` by design; the catalog
  additions are all hedged (point-fit/recovery, planned intervals/coverage, no
  supported/coverage-ready/interval-ready wording); claim guard stays exit 0. The new
  freshness guard is the systematic drift-catcher Rose asked for.
- **Noether (key↔engine↔doc):** the rename is a pure relabel — `dimension_pattern`
  stays `q12`, `fit_status`/`interval_status`/`coverage_status`/`authority` unchanged,
  widget-state counts unchanged (16/5/3). No likelihood, transform, or C++ path is
  involved. The README/ROADMAP formulas (`1 + x + z | p | …`, q=6 → 6 members/15 corr,
  q=12 → 12 members/66 corr) match `docs/design/01-formula-grammar.md` lines 148–149.
- **Fisher (inference honesty):** no interval/coverage/supported claim was added; q12 is
  described as `pdHess=FALSE` recovery-only with profile/bootstrap-routed correlations and
  ELR excluded, matching the locked doctrine.

## 9. What did not go smoothly

The primary gates failed on first run in the fresh worktree — not from the rename but
because gitignored recovery-checkpoint and ayumi-convergence evidence is absent from a
new worktree. Diagnosed via a `git stash` before/after comparison (identical error set),
then reproduced the maintainer environment by copying the referenced gitignored artifacts
from the main checkout. Worth remembering for any future worktree-based validation run.

## 10. Known residuals

- The dated historical records intentionally retain `_q8_planned` as the pre-rename
  narrative; this report is the completion record.
- The freshness guard covers `q12` today; extend `CATALOG_REQUIRED_DIMENSION_PATTERNS`
  as higher-q cells admit. (q6 is already documented in both catalogs but not yet
  guarded, matching the task's q12-only scope.)
- Q-Series surface is unchanged at 102/104 (Gaussian-complete); only the 2 non-Gaussian
  rows remain for 104.

## 11. Team learning

Placeholder keys that outlive their placeholder dimension are a real debt: a stable-key
ship (M2/M3) trades naming honesty for a clean admitting diff, and the follow-up rename
must move the key in lockstep across every surface that cross-checks it (source TSV +
hardcoded validator set + derived ledger + example lists), or the very gates that protect
the ledger reject it. And in a git-worktree world, "gate fails" is not "change is wrong"
until a stash-diff separates real regressions from gitignored-evidence absence.
