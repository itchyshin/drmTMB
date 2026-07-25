# After-task report — estimator-surface evidence-anchor hygiene

**Date:** 2026-07-25
**Scope:** one fixture file (`docs/dev-log/dashboard/estimator-surface-conformance.tsv`)

## 1. Purpose

Restore a trustworthy baseline test signal. Seven expectations in
`tests/testthat/test-estimator-surface-conformance.R` failed on untouched `origin/main`.
The failures were baseline debt, not a regression from the merged Julia extractor work.

## 2. Boundary

No estimator, likelihood, public API, capability tier, ledger status, or documentation
claim changed. This edits evidence line numbers in one TSV. Seven insertions, seven
deletions, one file.

## 3. What actually failed

The conformance test's first block enforces that every `evidence` pointer (`file:line`)
still contains the `detail` string the test matches on — a deliberate guard, added
2026-07-08, against citations rotting when unrelated edits shift line numbers. That guard
fired correctly: the anchors had drifted.

## 4. Diagnosis before repair

Each failing row was classified as **drifted anchor** (detail string still present in the
cited file, at a new line) versus **semantic change** (string gone, meaning the declared
behaviour had actually changed). This distinction governs whether the repair is a fixture
update or a capability question.

**All seven were drifted anchors. None was semantic.** Every cited `cli::cli_abort()`
message still exists, verbatim, in its original file.

Because five of the seven `detail` strings occur two or three times in `R/drmTMB.R`, each
candidate site was inspected individually to confirm it is the abort belonging to *that*
gate, rather than a coincidental substring match. The drift is regionally consistent
(+25 lines near line 250, +39 near 2150-2200), consistent with insertions upstream.

| cell_id | old | new |
| --- | --- | --- |
| `reml_on_base_confint_profile_fixef` | `R/profile.R:848` | `R/profile.R:867` |
| `reml_gate_poisson` | `R/drmTMB.R:241` | `R/drmTMB.R:266` |
| `reml_gate_aggregate_gaussian` | `R/drmTMB.R:2168` | `R/drmTMB.R:2207` |
| `reml_gate_sparse_fixed` | `R/drmTMB.R:2157` | `R/drmTMB.R:2196` |
| `reml_gate_ordinary_direct_sd` | `R/drmTMB.R:2200` | `R/drmTMB.R:2239` |
| `reml_gate_missing_engine_na` | `R/drmTMB.R:254` | `R/drmTMB.R:279` |
| `reml_gate_sd_phylo_plus_sigma_phylo` | `R/drmTMB.R:12169` | `R/drmTMB.R:12455` |

## 5. Validation

- `NOT_CRAN=true ... testthat::test_file("tests/testthat/test-estimator-surface-conformance.R")`
  — **147 passing expectations, 0 failures, 0 errors, 0 skips.** `NOT_CRAN=true` means the
  two `skip_on_cran()` blocks ran, so the live REML admission gates were exercised against
  real fits, not merely the anchor text.
- Full local suite: see the PR body for the recorded result.

## 6. Claim discipline

This repair asserts only that the conformance table's citations point where they claim to.
It establishes no interval, coverage, recovery, or tier claim, and promotes no cell.

## 7. Risks and limitations

The guard checks that a cited region *contains* the detail string; it does not verify the
citation is the most semantically apt site. That was verified here by inspection, but it
remains a human judgement, not an automated one.

## 8. Adjacent observation (not repaired here)

`docs/dev-log/check-log.md` (~4.7 MB, append-only) is a structural conflict magnet: nearly
every PR appends to it, so concurrent PRs collide there for no substantive reason. PR #829
is currently conflict-dirty **solely** because of this file — its actual one-line
`_pkgdown.yml` change merges clean. Worth a separate decision (per-run log files, or drop it
from version control). Not fixed here; out of scope.

## 9. Follow-up

If these anchors drift again, prefer a more durable citation form (a stable marker or a
grep-based locator) over another manual line-number refresh.
