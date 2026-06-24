# After Task: Structured RE Fixture Adapters

## 1. Goal

Finish the next five structured random-effect slices: q1 parity fixture,
q1 payload/reconstruction hardening, q2 same-target fixture, q4 extractor
boundary fixture, and ADEMP pilot adapters.

## 2. Implemented

Added deterministic fixture helpers under `inst/sim/R/` for q1 payloads,
reconstruction maps, bridge parity status rows, q2 target separation, and q4
direct-SD versus derived-correlation boundaries. Extended the ADEMP scaffold to
write mock pilot replicate rows and denominator summaries so later DGP/fitter
adapters inherit failed-fit and unavailable-interval accounting from the start.

The dashboard executable-evidence ledger now has 12 rows and uses robust
`devtools::test(filter = ...)` commands for all evidence rows.

## 3a. Decisions and Rejected Alternatives

I banked fixture and blocker evidence rather than pretending the R-via-Julia q1
route is live. The q1 parity fixture returns `blocked` when native R/TMB and
direct DRM.jl fixture targets agree but no bridge reconstruction is available.
That preserves the known Route A all-node logLik blocker.

I did not add live q2 or q4 bridge fits in this slice. The current claim is a
deterministic contract and adapter layer only, which is the right grain before
running row-specific native/direct/bridge evidence.

## 4. Files Touched

- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `inst/sim/R/sim_structured_re_ademp.R`
- `inst/sim/run/sim_write_structured_re_ademp_scaffold.R`
- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `tests/testthat/test-structured-re-ademp-scaffold.R`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-22-structured-re-fixture-adapters.md`

## 5. Checks Run

```sh
air format inst/sim/R/sim_structured_re_bridge_fixtures.R \
  inst/sim/R/sim_structured_re_ademp.R \
  inst/sim/run/sim_write_structured_re_ademp_scaffold.R \
  tests/testthat/test-structured-re-bridge-fixtures.R \
  tests/testthat/test-structured-re-ademp-scaffold.R
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures')"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-ademp-scaffold')"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
Rscript --vanilla -e "devtools::test(filter = 'structured-re')"
python3 tools/validate-mission-control.py
git diff --check
```

Outcomes:

- Bridge fixture tests: 42 pass, 0 failure, 0 warning, 0 skip.
- ADEMP scaffold tests: 48 pass, 0 failure, 0 warning, 0 skip.
- Conversion contract tests: 65 pass, 0 failure, 0 warning, 0 skip.
- `devtools::test(filter = 'structured-re')`: 155 pass, 0 failure, 0 warning,
  0 skip.
- Mission-control validator passed and reported 12 executable-evidence rows.
- `git diff --check` was clean.

## 6. Tests of the Tests

The bridge-fixture test initially failed on the q4 interval-boundary wording,
which confirmed that it checks the literal no-interval claim rather than only
row presence. The older executable-evidence `test_command` pattern also failed
to turn that `test_file()` failure into a non-zero shell exit, so the ledger was
updated to use `devtools::test(filter = ...)` commands that fail hard.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. The Ayumi issue remains
parked. This task only prepares internal evidence for the future Ayumi-balanced
`phylo_*` audit and does not draft or post a reply.

## 8. Consistency Audit

Checked the SC251-SC260, SC271-SC280, SC301-SC310, and SC331-SC360 conversion
rows. They were already banked as contract/design rows; this task adds
executable fixture and pilot-adapter evidence underneath them. The mission
control validator sees all 12 executable-evidence rows and verifies their
schema, paths, statuses, and non-empty gates.

The new helpers keep q2 separate from q2-plus-q2 and q4, keep q4 direct SD
targets separate from derived correlations, and keep coverage as not evaluated
or unavailable.

## 9. What Did Not Go Smoothly

The first TSV rewrite attempt tripped shell quoting before touching the file. I
then used R's TSV parser to update the command column without disturbing tabs.
The stronger test gate also exposed that the old `test_file()` shell pattern
could miss a failing test result.

## 10. Known Residuals

The q1 Route A R-via-Julia bridge remains blocked by the all-node logLik path.
No live native/direct/bridge parity, q2 bridge support, q4 bridge support, q4
interval evidence, or calibrated ADEMP coverage grid is claimed here.

## 11. Team Learning

Executable evidence rows should use commands that fail hard in the shell. When
a row is meant to bank negative evidence, make the status object itself say
`blocked`, `unsupported`, `not_evaluated`, or `unavailable` instead of hiding the
boundary in prose.
