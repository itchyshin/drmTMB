# After Task: Ayumi Inference Gap Ledger A071-A080

## 1. Goal

Bank the inference wave for the Ayumi phylogenetic balance arc without
collapsing fit support, target availability, bootstrap plumbing, direct Julia
machinery, and calibrated coverage into one claim.

## 2. Implemented

Added two dashboard ledgers:

- `docs/dev-log/dashboard/ayumi-inference-coverage-ledger.tsv`
- `docs/dev-log/dashboard/ayumi-boundary-status-ledger.tsv`

Added `docs/design/203-ayumi-inference-gap-ledger.md`, added a direct-DRM.jl
q4 profile/bootstrap row to `q4-target-inventory.tsv`, and banked A071-A080 in
`ayumi-phylo-balance-100-slices.tsv`.

## 3a. Decisions and Rejected Alternatives

The inference wave treats direct DRM.jl q4 profile/bootstrap support as design
input, not as an R bridge route. I rejected wording that would turn
`profile_ready` into interval coverage, because no replicated Ayumi-scale
coverage grid exists.

I also rejected treating `pdHess = FALSE` as a fit-erasing failure. The ledger
uses it as an inference warning: Wald intervals are unsafe, but point/status
rows can still be useful diagnostics.

## 4. Files Touched

- `docs/design/203-ayumi-inference-gap-ledger.md`
- `docs/dev-log/after-task/2026-06-22-ayumi-inference-gap-ledger.md`
- `docs/dev-log/dashboard/ayumi-inference-coverage-ledger.tsv`
- `docs/dev-log/dashboard/ayumi-boundary-status-ledger.tsv`
- `docs/dev-log/dashboard/q4-target-inventory.tsv`
- `docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/197-ayumi-phylo-balance-research-100-slices.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `tools/validate-mission-control.py`

## 5. Checks Run

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/tmp/drm-status.json
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/tmp/drm-sweep.json
tools/validate-mission-control.py
git diff --check
/Users/z3437171/.juliaup/bin/julia --project=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot -e 'using DRM; names_to_check = (:fit_q4_sparse_tmb, :profile_sigma_a, :bootstrap_sigma_a, :confint, :drm); for n in names_to_check println(string(n), "=", isdefined(DRM, n)) end'
```

The initial dashboard validation before the inference edits passed. The direct
DRM.jl source check reported all five queried bindings as defined.

## 6. Tests of the Tests

This slice added validator-owned ledgers rather than package behavior. The
tests-of-the-tests are schema and status guards in
`tools/validate-mission-control.py`: missing required coverage rows, missing
required boundary rows, invalid statuses, or nonexistent evidence links should
fail the dashboard validation.

## 7a. Issue Ledger

No GitHub issue was opened or updated. A076 remains a local status-hardening
decision: the existing endpoint-profile budget row returns `profile_failed`
status; a subprocess watchdog should become an issue only if compiled-code
profiles fail to return.

## 8. Consistency Audit

The inference rows were checked against:

- `docs/dev-log/dashboard/phylo-profile-loglik-status.tsv`
- `docs/dev-log/dashboard/bootstrap-refit-accounting.tsv`
- `docs/dev-log/dashboard/phylo-extractor-status.tsv`
- `docs/dev-log/dashboard/scale-phylo-diagnostics.tsv`
- `docs/dev-log/after-task/2026-06-15-endpoint-profile-budget-status.md`
- `docs/dev-log/after-task/2026-06-15-ayumi-q4-bootstrap-optimizer-controls.md`
- `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot/docs/dev-log/after-task/2026-06-13-bivariate-bootstrap-sigma-a.md`

## 9. What Did Not Go Smoothly

The main friction is conceptual rather than mechanical. Direct DRM.jl has
useful q4 interval machinery, but prior bootstrap evidence already shows
scale-axis undercoverage. That makes the Julia side scientifically useful while
also preventing any simple "Julia solves Ayumi uncertainty" statement.

## 10. Known Residuals

Coverage remains mostly not evaluated. Native TMB q4 REML is unsupported.
Native q4 ML bootstrap is not stable beyond the small smoke rows. The R bridge
still lacks row-specific native/direct/bridge inference parity for promoted
Ayumi cells.

## 11. Team Learning

Keep direct target readiness, returned interval status, and calibrated coverage
as three different columns. They answer different questions, and collapsing
them is exactly how an applied user would be misled.
