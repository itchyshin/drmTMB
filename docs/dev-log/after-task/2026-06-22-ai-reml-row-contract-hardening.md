# After Task: AI-REML Row-Contract Hardening

## Goal

Carry the exact-Gaussian location-only AI-REML transfer lane through the next 20
slices: package the banked implementation and mission-control evidence, then
harden the row contract and dashboard drift guards without promoting bridge,
q4, non-Gaussian, coverage, public optimizer, Ayumi-facing, or 10k-scale claims.

## Implemented

The already-banked work was committed in two focused commits: DRM.jl commit
`dc2ee87` for implementation/evidence and drmTMB commit `8544aff4` for
mission-control documentation. A third DRM.jl commit, `7968a5c`, hardened the
simulation-status contract with an explicit schema-drift test, malformed row
contract writer failure, row provenance, an optional large-stress skipped row,
and a validation-status README.

The local issue-comment draft now reflects the row-contract evidence and the
370-assertion focused test, but it remains a draft and was not posted.

`tools/validate-mission-control.py` now has two additional lints:

- a matrix row cannot mark simulation `covered` while its evidence text says
  coverage is not evaluated;
- exact `ai_reml_ready = true` wording is rejected unless a promoted optimizer
  gate is explicitly named.

## Mathematical Contract

The implementation evidence remains restricted to the exact Gaussian
location-only phylogenetic mean cell:

```text
y_i = X_i beta + u_species(i) + epsilon_i
u ~ N(0, sigma_phy^2 Sigma_phy)
epsilon ~ N(0, sigma^2 I)
```

This is not evidence for q4, Laplace, non-Gaussian, bivariate location-scale,
R bridge, Ayumi, or 10k-scale interval claims.

## Files Changed

- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/issue-drafts/2026-06-21-drmjl291-drmtmb555-ai-reml-postgate.md`
- `docs/dev-log/after-task/2026-06-22-ai-reml-row-contract-hardening.md`
- `docs/dev-log/recovery-checkpoints/2026-06-22-051517-codex-checkpoint.md`

The paired DRM.jl worktree changes are committed in
`/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`.

## Checks Run

```sh
cd "/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot"
julia --project=. test/test_location_only_reml_mme.jl
julia --project=. tools/loconly-reml-simulation-status.jl --output docs/dev-log/validation-status/2026-06-21-loconly-reml-simulation-status.tsv
tmp=$(mktemp -d)/loconly-status-medium.tsv; julia --project=. tools/loconly-reml-simulation-status.jl --with-medium-stress --output "$tmp" && wc -l "$tmp"
tmp=$(mktemp -d)/loconly-status-large.tsv; julia --project=. tools/loconly-reml-simulation-status.jl --with-large-stress --output "$tmp" && wc -l "$tmp"
git diff --check
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|10k sigma|10,440.*interval|Ayumi reply|public estimator claim|ai_reml_ready = true" docs/design/178-ai-reml-hsquared-transfer-gate.md docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-22-ai-reml-row-contract-hardening.md docs/dev-log/issue-drafts/2026-06-21-drmjl291-drmtmb555-ai-reml-postgate.md tools/validate-mission-control.py
```

The focused DRM.jl test passed: 370/370 assertions. Default TSV writing,
optional medium stress, optional large-stress skipped row, mission-control JSON
parsing, mission-control validation, recovery checkpoint creation, and
`git diff --check` all passed.

## Tests Of The Tests

The DRM.jl focused test now fails if the schema changes without updating the
explicit expected tuple. It also checks that malformed status rows are rejected
before TSV writing, that the optional large-stress path records a skipped row
when no runtime budget is supplied, and that provenance rows connect default
row IDs to helpers, tests, artifacts, and claim boundaries.

The drmTMB validator additions protect future dashboard edits from upgrading
diagnostic-only rows into covered simulation or AI-REML-ready language.

## Consistency Audit

The dashboard still reports AI-REML-inspired algorithms as partial and the R
bridge as unsupported. The issue draft remains local. No Ayumi reply was
drafted or posted.

## GitHub Issue Maintenance

No GitHub issue was edited, commented on, closed, or opened. The existing local
draft for `DRM.jl#291` / `drmTMB#555` was refreshed but not posted.

## What Did Not Go Smoothly

The first CLI smoke after adding `--with-large-stress` failed because the TSV
writer wrapper did not yet forward the new large-stress keywords to
`_loconly_reml_simulation_status()`. The focused smoke caught it before commit,
and the wrapper now forwards those controls.

## Team Learning

When a row contract becomes a dashboard dependency, the package-side dashboard
validator should block the two easiest overclaims: coverage status drift and
AI-REML readiness drift.

## Known Limitations

No external comparator dependency has been added. The optional large-stress row
is skipped unless a runtime budget is explicitly supplied. The evidence remains
point-recovery and boundary diagnostic evidence only, with no interval
coverage, public optimizer, R bridge, q4, non-Gaussian, Ayumi-facing, or
10k-scale claim.

## Next Actions

If publishing this lane, push the DRM.jl branch and the drmTMB mission-control
branch as separate draft PRs. Keep any external-comparator work as a separate
developer-only issue or draft PR.
