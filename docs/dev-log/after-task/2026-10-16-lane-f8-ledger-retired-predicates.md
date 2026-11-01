# Lane f8: scan every ledger row for retired gate predicates

## Goal

Implement #1011 suggested fix 1 for every ledger row. The reader is a
maintainer who deletes a gate predicate and needs `--check` to name every
ledger sentence that still cites it. Before this change the only guard was
the keyed `retired_predicate_absent` contract in `live-prose-contracts.tsv`,
which reads only the cells it names (`mr-beta`, `mr-tweedie`,
`mr-skew-normal`). Instance 3 of #1011 is the case it misses: held routes'
`next_gate` cells cited "the all-1200 interval-usability rule" after
`19e4a1d03` had replaced that rule with the `mr-g5-calibration-v2`
availability floor, and no contract named those rows.

## Implemented

- `validate_retired_predicates(cells, evidence)` in
  `tools/capability_ledger.py` reads every cell's `claim_boundary` and
  `next_gate` and every evidence row's `claim_boundary` (751 cells and 1,087
  evidence rows today). It fails if any of them contains a sidecar phrase,
  ignoring case and runs of whitespace. Each hit names `table:id.field`, the
  phrase, and its replacement, for example
  `cells:mc-0004.next_gate: retired predicate 'all-1200 interval-usability
  rule'; replaced by mr-g5-calibration-v2 interval-availability floor (...)`.
  `load_sources()` calls it after `validate_live_prose_contracts()`, so
  `--check`, `--write`, and `--summary` all refuse such a ledger.
- `docs/dev-log/dashboard/capability-ledger/retired-predicates.tsv` (new)
  has the columns `phrase`, `retired_by`, `replacement`, and `reference`. Its
  one row is `all-1200 interval-usability rule`, retired by
  `19e4a1d03c8fa167886b5b13dbbfcda874c1ac56` (confirmed on `main` through the
  GitHub API) and replaced by `MR_G5_AVAILABILITY_FLOOR <- 0.99` under
  `policy_id = "mr-g5-calibration-v2"`
  (`inst/sim/R/sim_missing_response_g4g5.R:983,1001`).
  `retired_predicate_phrases()` rejects a wrong header, a blank, missing, or
  extra field, and a duplicate phrase.
- `transitions.tsv` and the `notes` column are not scanned. They are history,
  and a note recording that a rule was retired must stay legal; a test pins
  the `notes` exclusion.
- The ledger `README.md` documents the sidecar and the rule that a deleted
  predicate's phrase is added there in the same change.

The keyed `retired_predicate_absent` contracts are unchanged. They still pin
their three rows; the sidecar scan covers those rows too.

#1007 needed no code. On `main`, `tools/mr-g5-reconcile.R` (lines 30, 36,
54-55) and `tools/mr-g5-reconcile-cohort.R` (lines 24-26, 36-37) embed
`expected_registry` and `expected_cell_count`, and
`mr_g5_validate_cohort_registry()`
(`inst/sim/R/sim_missing_response_g4g5.R:1226`) stops on dropped cells,
tested in `tests/testthat/test-missing-response-g4g5-foundation.R:446-472`.

## Files

- `tools/capability_ledger.py`
- `tools/tests/test_capability_ledger.py`
- `docs/dev-log/dashboard/capability-ledger/retired-predicates.tsv` (new)
- `docs/dev-log/dashboard/capability-ledger/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/team-improvements.md`
- this report

## Checks

The environment was R 4.3.3 with Ubuntu `r-cran-*` packages from apt
(devtools 2.4.5, roxygen2 7.3.1, TMB 1.9.10, testthat 3.2.1, ape 5.7-1). The
network policy blocked CRAN and Posit Package Manager.

- Red at `368eff52`: `python3 -m unittest tools.tests.test_capability_ledger`
  gave `Ran 82 tests ... FAILED (errors=2)`, both
  `AttributeError: module 'capability_ledger' has no attribute
  'validate_retired_predicates'`. At base `ca3ddefa` the 80 tests pass.
- Green at head: the same command gives `Ran 86 tests ... OK`, and
  `python3 tools/capability_ledger.py --check` gives
  `capability-ledger: OK (31 generated outputs)`.
- The rest of the CI step "Validate generated capability ledger" also passes
  locally. The other five wired Python suites pass (3, 3, 12, 5, and 24
  tests). `emit-profile-truth-manifest.R --check` reports `OK (30 rows)`,
  and `check-capability-runtime.R` reports `OK (18 routes; ... verified=18)`.
  The neighbouring guards pass too: `check-evidence-citations.R` finds 0
  violations in 37 rows, and `run-source-tree-tests.R --check` agrees with
  `.Rbuildignore` on 38 files.
- Near-miss audit:
  `grep -niE "all-1200|all 1200|interval-usability|usability rule" cells.tsv
  evidence.tsv transitions.tsv` finds nothing. The `1200 interval` hits are
  measurements such as `1200/1200 interval-usable (100%)`, not citations of
  the retired rule, and are correctly not flagged.

The R test suite was not run. No R file changed, and the narrow R guards
above are what CI runs for this surface.

## Tests of the tests

Fifteen mutants of the new code were run against the `-k retired` tests. In
the first pass 11 were killed. The four survivors were: deleting the
blank-field guard, folding only case on the scan side, also scanning `notes`,
and deleting the header check. The tests were then hardened:

- a scan-side test with mixed case, a tab, and a double space;
- a provenance test with blank, short, and extra-column rows;
- an assertion that `notes` produces no hit;
- the `load_sources()` test now retires `active_g5_policy_version()`
  instead of a literal `mr-g5-calibration-v2`, so it keeps working after
  the next policy bump.

On the rerun 14 of 15 mutants are killed. The survivor deletes the header
check; a renamed column then fails with a `KeyError` traceback instead of the
schema message, so the ledger still fails closed.

An independent review raised three blocking findings, all about text, not
code. The PR body's file list and test count were wrong; the CI "red proof"
it cited never ran (see below); and it said `document()` had no output. All
three are corrected in the PR body and in this report. A skeptic refuted two
should-fix code findings as outside #1011 item 1; they are recorded under
limitations.

## `devtools::document()`

`devtools::document()` was run and its output was not committed. DESCRIPTION
records `RoxygenNote: 7.3.2` and `Config/roxygen2/version: 8.0.0`; the
installed roxygen2 was 7.3.1. It rewrote 40 `man/*.Rd` files (214 insertions,
191 deletions, 109 hunks), although this branch touches no `R/`, `man/`,
`DESCRIPTION`, or `NAMESPACE` file.

A hunk-by-hunk attribution replayed the reverse of `592aecaa` (#1400) with a
three-way merge over later edits. It found 102 hunks that undo #1400 and 7
roxygen2 7.3.1 artifacts; none came from this branch. #1400 replaced internal
process language in the reference help by editing `man/` directly, while the
roxygen comments in `R/` kept the old wording ("Arc 6 accepts only", "The
first fitted route builds"). The 7 artifacts are cross-package links written
to the Rd file rather than the topic (`base:beta` to `base:Special`,
`stats:binomial` to `stats:family`, `stats:BIC` to `stats:AIC`) and the
dropped sole-maintainer Authors block. Committing the output would have
reverted #1400 in 38 pages, which AGENTS.md forbids without an explicit
request. For this branch the correct `document()` result is no change.

One #1400 page has already been lost this way: `2d29f9fe` regenerated
`man/beta_family.Rd` from `R/family.R`, and `main` again reads "remains
fixed-effect in this first slice".

## What did not go smoothly

The first push carried only the forcing-test commit, so review blocked the
PR: its body described an implementation that was not on the branch. A later
session wrote the implementation against that body and the forcing tests.

The R-CMD-check run for the forcing commit (`38856464754`) was still queued
when the fix was pushed. `cancel-in-progress` cancelled it before any shard
started, so the red proof is the local reproduction above, not a CI log.

## Team learning

- A PR whose "Files touched" list does not match
  `git diff --stat origin/main...HEAD` should not leave the session.
- `document()` output must be attributed before it is committed; recorded in
  `team-improvements.md` (2026-10-16).
- The sidecar is a closed list of banned phrases. The 2026-08-15
  team-improvement entry warns that such a list cannot enforce an open-ended
  claim class. It fits here only because each deleted predicate has a fixed
  name, so one row per deletion is complete for that deletion.

## Design docs, pkgdown, NEWS

No grammar, likelihood, family, or reader-facing behaviour changed, so no
design doc, vignette, or pkgdown page changes. Per the lane rule, the NEWS line
is carried in the PR body and not edited in-tree:
"Capability ledger: `--check` now rejects retired gate phrases in any row's
prose."

## GitHub issues

#1011 and #1007 are referenced, not closed. #1011 items 2 (route-name
cross-reference check) and 3 (keyed cross-reference columns) remain open.
#1140 (roxygen2 8.0.0 versus `RoxygenNote` 7.3.2) is the open issue nearest
to the `document()` drift. The #1400 hand edits are a second cause of the
same symptom; no comment was posted, and the decision is left to the owner.

## Known limitations and next actions

- The scan matches listed phrases only. It does not derive retired predicates
  from `mr_g5_calibration_gate()`. A policy rename that keeps every predicate
  (v2 to v3) leaves six uncontracted `next_gate` rows saying "Under
  mr-g5-calibration-v2" with `--check` green. That is version-label drift,
  which belongs to #1011 item 2 or 3.
- Reader prose hard-coded in the generator (`MISSING_G5_ROUTE_SUMMARIES`) is
  not scanned. It is source code, not a ledger cell.
- A phrase in a `retired_predicate_absent` contract does not yet have to
  appear in `retired-predicates.tsv`. A subset check would keep the two lists
  from drifting.
- Port the #1400 wording into the roxygen comments of the 19 affected `R/`
  files and settle the roxygen2 version (#1140), so that `document()` is a
  no-op on `main`.
