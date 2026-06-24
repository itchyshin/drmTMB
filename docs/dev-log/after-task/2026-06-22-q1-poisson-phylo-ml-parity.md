# After Task: Q1 Poisson Phylo ML/Laplace Parity

## 1. Goal

Bank SR117 by recording the existing q1 Poisson `phylo()` bridge evidence as
row-specific ML/Laplace parity, while keeping non-Gaussian REML and broader
count support out of scope.

## 2. Implemented

No model code changed for this row. The existing live
`tests/testthat/test-julia-phylo-count.R` evidence was rerun and promoted into
the validator-owned dashboard rows. The dashboard now records that the Poisson
q1 phylo bridge fixture checks finite fit status and approximate dense-TMB
parity for log-likelihood, fixed coefficients, and the structured SD.

The balance matrix, bridge parity smoke table, executable-evidence table, q1
fixture contract, Julia twin-sync table, status JSON, sweep JSON, finish-plan
note, capability matrix, Ayumi bridge readiness note, and check-log now all
name the same boundary.

## 3a. Decisions and Rejected Alternatives

I did not turn the row into a broad "count phylo bridge" claim. The executable
parity fixture is Poisson-specific. NB2 routing/gating evidence exists nearby,
but NB2 parity was not added or claimed in this row.

I did not use REML or AI-REML wording for the count route. The evidence is
non-Gaussian ML/Laplace bridge evidence only.

## 4. Files Touched

- `docs/dev-log/dashboard/bridge-parity-smoke-status.tsv`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/structured-re-balance-matrix.tsv`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/structured-re-finish-100-slices.tsv`
- `docs/dev-log/dashboard/structured-re-julia-twin-sync.tsv`
- `docs/dev-log/dashboard/structured-re-q1-parity-fixture-contract.tsv`
- `docs/dev-log/dashboard/sweep.json`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/200-ayumi-julia-bridge-balance-readiness.md`
- `docs/design/216-structured-random-effect-finish-100-slices.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-22-q1-poisson-phylo-ml-parity.md`

## 5. Checks Run

```sh
DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot \
  DRM_JL_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot \
  Rscript --vanilla -e "devtools::test(filter = 'julia-phylo-count')"
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh -n tools/start-mission-control.sh
git diff --check
Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R \
  docs/dev-log/after-task/2026-06-22-q1-poisson-phylo-ml-parity.md
```

Result: `julia-phylo-count` passed with 29 assertions, 0 failures, 0 warnings,
and 0 skips in 17.3 seconds. `tools/validate-mission-control.py` passed with
12 bridge parity-smoke rows and 21 executable-evidence rows. `status.json` and
`sweep.json` parsed as JSON, `sh -n tools/start-mission-control.sh` passed,
`git diff --check` was clean in both active worktrees, and the after-task
report validator passed.

## 6. Tests of the Tests

The test would fail if the bridge stopped routing Poisson `phylo()` through the
large-p phylo route, if the fit became non-finite, or if the native dense-TMB
and R-via-Julia log-likelihood, coefficient, or structured-SD parity tolerances
stopped holding.

## 7a. Issue Ledger

No GitHub issue, comment, PR, commit, or Ayumi reply was created. SR117 is
local mission-control evidence only. The next row is SR118: unsupported q1
route errors before JuliaCall.

## 8. Consistency Audit

The dashboard now uses `experimental` bridge status for the Poisson q1 phylo
row and names the exact evidence path. It still marks inference unsupported and
keeps NB2 parity, non-phylo count bridge support, REML, intervals, q2/q4, and
public bridge promotion outside the row.

## 9. What Did Not Go Smoothly

This row did not require new implementation. The main risk was wording drift:
the previous queued row said "count phylo" but the executable parity evidence
is Poisson-specific. The dashboard now says that explicitly.

## 10. Known Residuals

NB2 bridge parity, count interval status, calibrated coverage, q2/q4 count
structured effects, and non-phylo count bridge support remain separate rows.
This row does not change the exact-Gaussian-only REML/AI-REML boundary.

## 11. Team Learning

Rose: dashboard wording should follow the narrowest executable evidence, not
the broadest row label. Fisher: non-Gaussian parity evidence must keep finite
fit, log-likelihood, coefficient, and variance-component checks separate from
interval reliability. Boole: status text should name the family when a row
label says "count" but the test only covers Poisson.
