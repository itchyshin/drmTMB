# After Task: Structured Bridge Unblock Smoke

## Goal

Try to unblock SR073-SR075 by running guarded live bridge tests against the
active DRM.jl worktree.

## Implemented

No ledger row was moved. The live smoke was recorded in
`docs/design/213-structured-bridge-readiness.md` and
`docs/dev-log/check-log.md` so the next bridge pass starts from evidence rather
than guesswork.

## Mathematical Contract

Bridge parity means row-specific agreement among native R/TMB, direct DRM.jl,
and R-via-Julia on the target being claimed. A finite bridge fit, a gate test,
or a q4 `corpairs()` reconstruction is useful evidence, but it is not parity by
itself.

## Files Changed

- `docs/design/207-structured-random-effect-balance-100-slices.md`
- `docs/design/213-structured-bridge-readiness.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-22-structured-bridge-unblock-smoke.md`

## Checks Run

The guarded live bridge command passed:

- `test-julia-sigma-phylo-reml.R`: 52 pass;
- `test-julia-structured.R`: 47 pass;
- `test-julia-phylo-q4-corpairs.R`: 27 pass.

## Tests Of The Tests

These tests exercise gate behavior, live bridge routing when the local DRM.jl
engine is available, and R-side q4 `corpairs()` reconstruction. They do not
assert coefficient/log-likelihood parity against native R/TMB and direct DRM.jl
for SR073-SR075.

## Consistency Audit

SR073-SR075 remain blocked in
`docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`. The bridge
readiness note now explicitly says the live smoke passed but parity is still
not row-complete.

## GitHub Issue Maintenance

No GitHub issue was changed.

## What Did Not Go Smoothly

The test results are encouraging enough to tempt promotion. That would be too
strong: the rows are named as bridge parity rows, and parity has not been
demonstrated.

## Team Learning

Bridge rows need three labelled evidence columns before they become support:
native R/TMB, direct DRM.jl, and R-via-Julia. Smoke evidence should improve the
blocker text, not erase the blocker.

## Known Limitations

No q1/q2/q4 bridge parity row was banked. No public R bridge support, optimizer
surface, q4 REML, non-Gaussian REML, or AI-REML claim was added.

## Next Actions

Build row-specific parity fixtures for SR073-SR075, starting with one q1 cell
that has native R/TMB and direct DRM.jl target values available in the same
scale.
