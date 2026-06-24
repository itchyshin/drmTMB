# Q2 Helper Dashboard Drift Correction

## 1. Goal

Correct a local source/test drift found while reviewing draft PR #638. The
dashboard sidecars already bank q2 bridge acceptance rows for phylo, fixed
covariance spatial, animal, and relmat fixtures, but the helper used by tests
still described the non-phylo q2 rows as planned or blocked.

## 2. Implemented

- Aligned the q2 payload fixture helper with the current dashboard boundary for
  `phylo`, `spatial`, `animal`, and `relmat` structured random-effect rows.
- Expanded the q2 fixture contract helper so all four q2 structured types carry
  route-specific ML fixture evidence, while `q2_plus` and `q2_reml` remain
  explicit boundary rows.
- Updated q2 coefficient-order, payload-provenance, and acceptance-gate helpers
  so their status, bridge-status, evidence URL, and missing-evidence fields
  match the banked dashboard rows.
- Updated the focused fixture tests to require the current q2 acceptance
  boundary instead of the stale planned/blocking wording.

## 3a. Decisions and Rejected Alternatives

This correction keeps the change source-local. It does not regenerate the
dashboard, expand user-facing bridge claims, or introduce new optimizer
controls. The dashboard sidecars remain the status ledger for PR #638, and the
R helper now mirrors that ledger for the columns exercised by tests.

## 4. Files Touched

- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-23-q2-helper-dashboard-drift-correction.md`

## 5. Checks Run

- `air format inst/sim/R/sim_structured_re_bridge_fixtures.R tests/testthat/test-structured-re-bridge-fixtures.R`
  passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures')"`
  passed with 254 assertions.
- A custom source-vs-dashboard check passed for the q2 acceptance gate,
  coefficient-order map, and payload-provenance status columns.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 1457 assertions.
- `git diff --check` passed.
- `python3 tools/validate-mission-control.py` passed with the r63 dashboard
  evidence set.

## 6. Tests of the Tests

The old fixture test would have continued to accept stale `planned` and
`blocked` wording for the non-phylo q2 rows. The updated test now requires all
four q2 ML structured types to be covered at the narrow fixture scope, and it
keeps q2 REML and q2-plus support outside the claim boundary.

The custom source-vs-dashboard check guards against the same drift recurring in
the acceptance, coefficient-order, and provenance helper tables.

## 7a. Issue Ledger

No GitHub issue or PR comment was opened, closed, or updated. This was a local
review correction for draft PR #638. No files were staged or committed.

## 8. Consistency Audit

The correction does not change the mission-control marker, which remains r63 in
the live widget. It keeps SR150 blocked and does not promote q4 interval
reliability, q4 interval coverage, q4 REML, native-TMB q4 REML, q4 AI-REML,
HSquared AI-REML, non-Gaussian AI-REML, broad bridge support, DRAC readiness, a
merge, or an Ayumi-facing reply.

## 9. What Did Not Go Smoothly

The dashboard and mission-control validator were already green, but the package
helper had drifted from the banked dashboard status rows. That means the green
validator did not by itself prove the helper source used by package tests was
current.

## 10. Known Residuals

Draft PR #638 remains a large evidence PR. Continue diff review before asking
whether to stage or commit this correction, and ask explicitly before
undrafting or merging the PR.

The dirty DRM.jl worktree for PR #297 is still unbanked and should be
reconciled separately from this q2 helper correction.

## 11. Team Learning

When a helper mirrors dashboard sidecars, Curie and Rose should require at
least one direct source-vs-dashboard consistency check for the status columns
that tests rely on. A passing widget validator is necessary evidence, but it is
not sufficient proof that package-side helper tables have not drifted.
