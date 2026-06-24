# After Task: Structured Coverage Unblock Pilots

## Goal

Unblock SR064-SR066 only if q1, q2, and q4 structured random-effect coverage
pilot rows could be banked with target-specific fit, Hessian, interval, and
failure accounting.

## Implemented

Added a repeatable pilot artifact under
`docs/dev-log/simulation-artifacts/2026-06-22-structured-coverage-unblock-pilots/`
and moved SR064-SR066 from `blocked` to `banked` in the structured
100-slice ledger. The pilot follows an ADEMP-shaped note and writes both
per-target rows and a cell-level summary.

## Mathematical Contract

The pilot targets Gaussian structured SDs only. A finite Wald interval, a
boundary interval, an unavailable Wald row, a non-positive Hessian, and a
coverage estimate are separate evidence classes. The pilot banks accounting
plumbing, not interval reliability.

## Files Changed

- `docs/dev-log/simulation-artifacts/2026-06-22-structured-coverage-unblock-pilots/README.md`
- `docs/dev-log/simulation-artifacts/2026-06-22-structured-coverage-unblock-pilots/run-pilot.R`
- `docs/dev-log/simulation-artifacts/2026-06-22-structured-coverage-unblock-pilots/tables/structured-coverage-pilot-rows.csv`
- `docs/dev-log/simulation-artifacts/2026-06-22-structured-coverage-unblock-pilots/tables/structured-coverage-pilot-summary.csv`
- `docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`
- `docs/design/207-structured-random-effect-balance-100-slices.md`
- `docs/design/212-structured-inference-status.md`
- `docs/design/215-structured-closeout-gates.md`
- `docs/dev-log/after-task/2026-06-22-structured-re-inference.md`
- `docs/dev-log/after-task/2026-06-22-structured-re-closeout-gates.md`
- `docs/dev-log/check-log.md`

## Checks Run

Checks are recorded in `docs/dev-log/check-log.md`. The pilot runner completed
with warnings and produced the corrected summary: q1 had one finite interval
from three interval rows; q2 and q4 had no finite intervals.

## Tests Of The Tests

The first pilot summary incorrectly counted unavailable intervals as finite
because it used non-missing `covered` values as the finite-interval flag. The
runner now counts finite intervals from finite lower and upper bounds, and the
rerun changed q2/q4 finite intervals from six/eight to zero.

## Consistency Audit

`docs/design/212-structured-inference-status.md` now says SR064-SR066 are
pilot-only accounting rows. `docs/design/207-structured-random-effect-balance-100-slices.md`
records the new 91 banked / 9 blocked disposition. A sibling status drift in
`docs/design/215-structured-closeout-gates.md` was corrected so SR093 remains
blocked until a current, approved reply draft exists.

## GitHub Issue Maintenance

No GitHub issue was changed. The Ayumi issue refresh and reply gates remain
blocked.

## What Did Not Go Smoothly

The useful result was less flattering than the first table suggested. q2 and q4
fit rows existed, but their Wald intervals were unavailable and the Hessian
status was not positive. That is exactly why this remains pilot evidence only.

## Team Learning

Coverage-pilot tables should count interval availability from the interval
bounds, not from the boolean coverage flag. Fisher's gate should read both the
row table and the summary before accepting a pilot as banked.

## Known Limitations

The pilot is tiny. It does not validate interval coverage, q4 uncertainty,
Ayumi-scale inference, native q4 REML, R-via-Julia bridge support,
non-Gaussian REML, or AI-REML.

## Next Actions

Leave SR073-SR075 blocked until bridge parity has native R/TMB, direct DRM.jl,
and R-via-Julia row evidence. Design a calibrated coverage grid only after the
target and failure taxonomy is stable.
