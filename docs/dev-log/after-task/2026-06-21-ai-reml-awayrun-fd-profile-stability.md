# After Task: AI-REML Away-Run FD And Local-Profile Stability

## Goal

Continue the exact-Gaussian diagnostic lane while the maintainer is away by
adding finite-difference stability, local-profile sanity, optimizer accounting,
and PEV summary evidence.

## Implemented

In the clean DRM.jl worktree, added FD gradient/Hessian stability diagnostics,
local profile diagnostics, optimizer accounting fields, and PEV summary fields.
The combined diagnostic payload now includes FD-stability and local-profile
subdiagnostics.

In drmTMB, updated the transfer-gate ledger, capability matrix, dashboard, and
check-log. No user-facing bridge or q4 claim changed.

## Mathematical Contract

All new diagnostics evaluate the same exact Gaussian restricted objective. The
finite-difference checks are numerical diagnostics, not analytic score or
average-information derivations.

## Files Changed

- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/178-ai-reml-hsquared-transfer-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/after-task/2026-06-21-ai-reml-awayrun-fd-profile-stability.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
tools/start-mission-control.sh --background
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|10k sigma|10,440.*interval|Ayumi reply" docs/design/178-ai-reml-hsquared-transfer-gate.md docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-21-ai-reml-awayrun-fd-profile-stability.md docs/design/168-r-julia-finish-capability-matrix.md
```

The focused DRM.jl test passed: 137/137 assertions in 7.1 seconds.

## Tests Of The Tests

The new checks assert finite-difference stability over multiple step sizes,
local-profile minimum behaviour at the optimizer point, optimizer start
accounting, PEV summary identities, and payload inclusion of the new
subdiagnostics.

## Consistency Audit

The dashboard row remains `partial`. No bridge row, public optimizer, q4,
Laplace, non-Gaussian, Ayumi-facing, or 10k interval claim is promoted.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

The first focused test after adding PEV summaries failed because the test needed
`Statistics.mean`. The import was added and the focused test passed.

## Team Learning

The finite-difference scaffold is now measurable enough to support an analytic
score derivation: we know what the numerical gradient, Hessian, profile slices,
and optimizer accounting look like before replacing them.

## Known Limitations

No analytic restricted score, true average-information update, R bridge wiring,
or full package test suite is included in this slice.

## Next Actions

Derive and test the analytic restricted score for the two log-SD variance
parameters against the finite-difference stability scaffold.
