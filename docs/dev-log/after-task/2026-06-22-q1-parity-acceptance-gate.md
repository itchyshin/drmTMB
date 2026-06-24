# After Task: Q1 Parity Acceptance Gate

## 1. Goal

Bank SR120 by closing the q1 bridge parity wave as local mission-control
evidence: fixtures, tolerances, coefficient-scale maps, and negative preflight
gates must agree before q2 work begins.

## 2. Implemented

Added a q1 acceptance-gate assertion to
`tests/testthat/test-structured-re-conversion-contracts.R`. It checks that the
q1 parity fixture table has banked experimental rows with tolerances and
R-via-Julia evidence, that the fixed-coefficient, structured-SD, and coupled
phylo reconstruction maps exist, that negative unsupported-route evidence is
banked, and that `structured-re-closeout-package.tsv` carries a covered
`q1_parity_acceptance_gate` row.

Updated the finish ledger, executable evidence, closeout package, twin-sync
row, dashboard JSON, design summaries, and check-log to make SR120 the q1
transition gate rather than a public bridge-support claim.

## 3a. Decisions and Rejected Alternatives

I did not mark q1 as broadly supported. The gate says the local q1 bridge
evidence is internally consistent enough to start q2 work. Interval coverage,
NB2 parity, non-phylo count bridge support, q2, q4, and public promotion remain
outside this row.

## 4. Files Touched

- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/structured-re-closeout-package.tsv`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/structured-re-finish-100-slices.tsv`
- `docs/dev-log/dashboard/structured-re-julia-twin-sync.tsv`
- `docs/dev-log/dashboard/sweep.json`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/216-structured-random-effect-finish-100-slices.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-22-q1-parity-acceptance-gate.md`

## 5. Checks Run

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh -n tools/start-mission-control.sh
git diff --check
Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R \
  docs/dev-log/after-task/2026-06-22-q1-parity-acceptance-gate.md
```

Result: `structured-re-conversion-contracts` passed with 97 assertions,
0 failures, 0 warnings, and 0 skips. `tools/validate-mission-control.py`
passed with 8 closeout-package rows and 24 executable-evidence rows.
`status.json` and `sweep.json` parsed as JSON,
`sh -n tools/start-mission-control.sh` passed, `git diff --check` was clean in
both active worktrees, and the after-task report validator passed.

## 6. Tests of the Tests

The new test would fail if q1 parity fixtures lost tolerances, if live
R-via-Julia paths reverted to planned, if coefficient-scale map rows disappeared,
if unsupported-route negative evidence disappeared, or if SR120 was marked
banked without the closeout-package gate.

## 7a. Issue Ledger

No GitHub issue, comment, PR, commit, or Ayumi reply was created. SR120 is local
mission-control transition evidence only. The next row is SR121: q2 phylo
location bridge boundary/design.

## 8. Consistency Audit

The q1 acceptance gate now appears in the finish ledger, executable evidence,
closeout package, status JSON, sweep JSON, design summaries, and check-log. Each
place states that the gate is local and route-specific, not broad bridge
promotion.

## 9. What Did Not Go Smoothly

No model code was needed. The main risk was overclaiming the q1 transition as
general support; the row wording explicitly avoids that.

## 10. Known Residuals

NB2 parity, interval coverage, non-phylo count bridge support, q2/q4 bridge
support, REML parity outside the exact-Gaussian scoped rows, and Ayumi-facing
communication remain separate gates.

## 11. Team Learning

Ada: transition gates are useful when they prevent a wave from leaking into the
next one. Rose: a banked acceptance gate still needs explicit non-claims.
Fisher: tolerances and scale maps belong in the same gate as numeric parity.
