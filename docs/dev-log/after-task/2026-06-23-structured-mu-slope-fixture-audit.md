# After Task: Structured Mu-Slope Artifact Fixture Audit

## Goal

Finish the next q-series control-plane slice after the provider-contract gate.
The task was to sweep the local PR #638 stack, reconcile stale provider-contract
next-gates, and bank the current one-slope Gaussian structured `mu` artifact
evidence without promoting bridge parity, intervals, coverage, `sigma` slopes,
or labelled structured covariance.

## Implemented

- Added `docs/dev-log/dashboard/structured-re-mu-slope-fixture-audit.tsv` with
  one row each for `phylo(1 + x | species, tree = tree)`,
  `spatial(1 + x | site, coords = coords)`,
  `animal(1 + x | id, A = A)`, and `relmat(1 + x | id, K = K)` in `mu`.
- Wired the new sidecar into `tools/validate-mission-control.py`, including
  field checks, required provider rows, evidence-path checks, and guards that
  bridge fixture, interval, and coverage statuses remain `planned`.
- Updated `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv` so
  structured q1 `mu` intercept rows no longer ask for provider contracts that
  are already banked, and one-slope `mu` rows point to the new audit sidecar.
- Updated `docs/design/218-structured-q-series-completion-map.md` and
  `docs/dev-log/dashboard/README.md` to describe the artifact audit as
  source-tested DGP, smoke-summary, grid-writer, and extractor evidence only.
- Updated `docs/dev-log/check-log.md` with PR state, focused test results,
  mission-control validation, and the next-slice plan.

## Mathematical Contract

This slice does not change model fitting. It records existing source-tested
artifact evidence for one independent Gaussian structured location (`mu`)
slope. Each row covers a DGP, smoke summary, grid writer, and extractor identity
for the exact provider/formula cell.

The audit does not assert bridge parity. It does not assert interval
reliability, coverage, residual-scale (`sigma`) structured slopes, labelled
structured slope covariance, q4/q6/q8 structured slope support, REML, or
AI-REML.

## Files Changed

- `docs/dev-log/dashboard/structured-re-mu-slope-fixture-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `tools/validate-mission-control.py`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-23-structured-mu-slope-fixture-audit.md`

This work sits on the existing dirty PR #638 stack. No files were staged or
committed.

## Checks Run

- `git status --short --branch` showed the expected dirty PR #638 stack.
- `git diff --check` passed before this slice began.
- `gh pr checks 638 --repo itchyshin/drmTMB --json name,state,workflow,link,bucket`
  showed Ubuntu, macOS, and Windows R-CMD-check jobs passing.
- `gh pr view 638 --repo itchyshin/drmTMB --json title,isDraft,headRefOid,mergeStateStatus,url`
  showed PR #638 is draft, merge-clean, and at head
  `009528d609519039bb8df13d84db779408f06499`.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reports 4 structured
  RE mu-slope audit rows.
- `Rscript --vanilla -e "devtools::test(filter = 'phase18-phylo-mu-slope')"`
  passed with 49 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'phase18-spatial-mu-slope')"`
  passed with 30 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'phase18-animal-mu-slope')"`
  passed with 48 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'phase18-relmat-mu-slope')"`
  passed with 48 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'phase18-random-slope-grid-writers')"`
  passed with 25 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-effects')"`
  passed with 268 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 1470 assertions.
- `git diff --check` passed.

## Tests Of The Tests

The four provider-specific Phase 18 tests exercise seeded DGPs, smoke summaries,
artifact writers, malformed-input rejection, and fitted SD labels. The shared
random-slope grid-writer test exercises the spatial writer beside ordinary
random-slope writers. The `structured-effects` test supplies the extractor
identity layer, including provider/observed levels and coefficient identity.

## Consistency Audit

The q-series support-cell table now points one-slope `mu` rows at the new audit
sidecar and keeps `bridge_status`, `interval_status`, and `coverage_status`
unchanged. The design note and dashboard README both state that the audit is
artifact evidence only.

The provider-contract next-gates for structured q1 `mu` intercept rows were
updated for spatial, animal, and relmat. Scale-side rows still require
endpoint-specific evidence and were not promoted.

## GitHub Issue Maintenance

No GitHub issue, PR body, PR comment, or Ayumi-facing reply was created or
updated. PR #638 remains draft.

## What Did Not Go Smoothly

The first repository search for one-slope evidence was noisy because ordinary
q6/q8 slope diagnostics, missing-data structured covariate examples, and
non-Gaussian slope text share the same words. The useful signal came from the
Phase 18 provider-specific test files and grid-writer files.

## Team Learning

The next q-series unit should separate three evidence layers: source-tested
artifact writers, same-target parity fixtures, and interval/coverage evidence.
Calling all three "fixture evidence" hides the promotion boundary too easily.

## Known Limitations

No runtime support changed. This audit does not add residual-scale structured
slopes, labelled structured slope covariance, structured q4/q6/q8 slopes,
bridge parity, interval reliability, coverage, q4 REML, native-TMB q4 REML,
q4 AI-REML, HSquared AI-REML, non-Gaussian AI-REML, public optimizer controls,
DRAC execution, or SR150 evidence.

## Next Actions

1. Add same-target one-slope `mu` bridge/parity fixture design rows for
   `phylo()`, fixed-covariance `spatial()`, `animal()`, and `relmat()`.
2. Implement the narrowest native/direct/R-via-Julia fixture for the provider
   with the least marshalling risk.
3. Keep `sigma` one-slope work as a separate tranche after the exact `mu`
   bridge/parity fixtures are mapped.
4. Leave structured labelled slope covariance, q4/q6/q8 slopes, REML,
   intervals, and coverage blocked until cell-specific evidence exists.
