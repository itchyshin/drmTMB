# After Task: Q1 Unsupported-Route Preflight Errors

## 1. Goal

Bank SR118 by proving the q1 structured bridge rejects unsupported routes before
JuliaCall: predictor-dependent `sigma`, precision-slot matrix forms, and bad
covariance shapes.

## 2. Implemented

No model code changed for this row. The existing gate and structured preflight
tests were rerun, then the finish ledger and executable-evidence dashboard were
updated to record the negative evidence.

The gate registry remains one-to-one with `bridge-rejection-messages.tsv`, so I
did not add a non-registry row for malformed covariance matrices. That internal
preflight evidence is instead recorded in `structured-re-executable-evidence.tsv`
with its test path.

## 3a. Decisions and Rejected Alternatives

I did not widen the Julia bridge to support sigma predictors, precision
matrices, or malformed covariance repair. SR118 is an intentional-error row.

I did not mark the skipped live structured Julia smoke as a failure. The skip is
about the optional DRM.jl general-covariance engine being unavailable in the
subprocess; SR118 only needs pre-JuliaCall and preflight error evidence.

## 4. Files Touched

- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/structured-re-finish-100-slices.tsv`
- `docs/dev-log/dashboard/structured-re-julia-twin-sync.tsv`
- `docs/dev-log/dashboard/sweep.json`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/216-structured-random-effect-finish-100-slices.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-22-q1-unsupported-route-preflight-errors.md`

## 5. Checks Run

```sh
Rscript --vanilla -e "devtools::test(filter = 'julia-gate-vs-engine|julia-structured')"
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh -n tools/start-mission-control.sh
git diff --check
Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R \
  docs/dev-log/after-task/2026-06-22-q1-unsupported-route-preflight-errors.md
```

Result: `julia-gate-vs-engine` and `julia-structured` passed with 185
assertions, 0 failures, and 0 warnings. One live structured Julia smoke skipped
because the optional DRM.jl general-covariance engine was unavailable; the
preflight and gate checks relevant to SR118 ran.

## 6. Tests of the Tests

The tests would fail if an intentional registry gate disappeared, if the
dashboard gate artifact drifted from the registry, if unsupported structured
sigma predictors or precision slots reached JuliaCall, or if malformed
structured matrices stopped producing preflight errors.

## 7a. Issue Ledger

No GitHub issue, comment, PR, commit, or Ayumi reply was created. SR118 is local
mission-control negative evidence only. The next row is SR119: q1 coefficient
and structured-SD scale map.

## 8. Consistency Audit

The dashboard now separates support rows from intentional-error rows. The
structured sigma-predictor and precision-slot gates remain in
`bridge-rejection-messages.tsv`, while malformed covariance shape remains
internal preflight evidence through `test-julia-structured.R`.

## 9. What Did Not Go Smoothly

The first temptation was to add a bridge-rejection row for non-square
covariances. The validator showed that table is deliberately one-to-one with
the gate registry, so the safer home is executable evidence rather than a fake
registry gate.

## 10. Known Residuals

This row does not design or implement sigma-side structured bridge support,
precision-matrix marshalling, matrix repair, intervals, q2/q4 bridge support,
or public support wording.

## 11. Team Learning

Grace: registry-backed gates and internal preflight checks should stay in
separate artifacts. Rose: negative evidence can be banked, but it must not look
like support. Emmy: bridge routes should fail before JuliaCall when the payload
contract is unsatisfied.
