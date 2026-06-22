# After Task: AI-REML Next 20 Comparator And Boundary Slices

## Goal

Run the next 20 local slices after the post-gate exact-Gaussian diagnostics,
focusing on comparator, boundary, optimizer-gate, diagnostic-payload, and
dashboard evidence.

## Implemented

In the clean DRM.jl worktree, added dense developer REML components,
sparse-vs-dense comparator diagnostics, boundary classification, observed
Hessian status inside the finite-difference optimizer diagnostic, and a combined
diagnostic payload. The focused test now includes dense-comparator checks,
boundary labels, payload-shape checks, optimizer Hessian checks, and a PEV
shrinkage sanity check.

In drmTMB, updated the transfer-gate ledger with a 20-slice completion record,
refreshed the AI-REML capability row and dashboard wording, and logged the
latest focused-test evidence.

## Mathematical Contract

The dense comparator evaluates the same exact Gaussian restricted objective as
the sparse helper. The optimizer diagnostic remains finite-difference LBFGS and
explicitly not AI-REML.

## Files Changed

- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/design/178-ai-reml-hsquared-transfer-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/after-task/2026-06-21-ai-reml-next20-comparator-boundary.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
tools/start-mission-control.sh --background
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|10k sigma|10,440.*interval|Ayumi reply" docs/design/178-ai-reml-hsquared-transfer-gate.md docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-21-ai-reml-next20-comparator-boundary.md docs/design/168-r-julia-finish-capability-matrix.md
```

The focused DRM.jl test passed: 122/122 assertions in 7.0 seconds.

## Tests Of The Tests

The new tests compare sparse REML components against a dense same-estimand
oracle, check boundary labels for near-zero variance, rank-deficient fixed
effects, and invalid inputs, verify observed-Hessian status at the optimizer
diagnostic point, and check that duplicate observations shrink or preserve leaf
PEV values.

## Consistency Audit

The dashboard row remains `partial`. No bridge row, public optimizer, q4,
Laplace, non-Gaussian, Ayumi-facing, or 10k interval claim is promoted.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

The boundary classifier needed one correction for rank-deficient fixed-effect
designs. That fix is covered by the focused test.

## Team Learning

The most useful next evidence is not a bigger name. It is a tighter diagnostic
payload that fails loudly when algebra, boundaries, or optimizer status drift.

## Known Limitations

No full DRM.jl or drmTMB suite was run. No external package comparator is added.
No AI update is implemented.

## Next Actions

Start the next engine slice from the analytic restricted-score derivation, or
deliberately freeze this helper as a diagnostic-only scaffold.
