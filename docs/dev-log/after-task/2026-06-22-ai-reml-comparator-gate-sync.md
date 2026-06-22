# After Task: AI-REML Comparator Gate Mission-Control Sync

## Goal

Mirror the DRM.jl external-comparator planning gate into drmTMB mission control
after the comparator status became row-shaped, without changing the bridge,
q4, non-Gaussian, coverage, public optimizer, Ayumi-facing, or 10k-scale claim
boundary.

## Implemented

The DRM.jl branch now has `_loconly_reml_external_comparator_status()`, which
keeps `external_comparator_status = planned`, `dependency_status = not_added`,
`coverage_status = not_evaluated`, and `ai_reml_ready = false`.

On the drmTMB mission-control side, the HSquared transfer ledger, dashboard
AI-REML-inspired row, active-work text, and local issue draft now mention that
planned comparator gate. The dashboard still records simulation as partial and
bridge support as unsupported.

## Mathematical Contract

The comparator gate is only for the exact Gaussian location-only phylogenetic
mean REML target:

```text
y_i = X_i beta + u_species(i) + epsilon_i
u ~ N(0, sigma_phy^2 Sigma_phy)
epsilon ~ N(0, sigma^2 I)
```

A future external comparator must match this restricted objective, covariance
target, boundary behavior, and variance-component estimates before it counts as
same-estimand evidence.

## Files Changed

- `docs/design/178-ai-reml-hsquared-transfer-gate.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/issue-drafts/2026-06-21-drmjl291-drmtmb555-ai-reml-postgate.md`
- `docs/dev-log/after-task/2026-06-22-ai-reml-comparator-gate-sync.md`

## Checks Run

```sh
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
tools/validate-mission-control.py
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|10k sigma|10,440.*interval|Ayumi reply|public estimator claim|ai_reml_ready = true" docs/design/178-ai-reml-hsquared-transfer-gate.md docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-22-ai-reml-comparator-gate-sync.md docs/dev-log/issue-drafts/2026-06-21-drmjl291-drmtmb555-ai-reml-postgate.md docs/dev-log/dashboard/status.json
```

Mission-control JSON parsed cleanly. `tools/validate-mission-control.py`
passed with `mission_control_ok: 25/68 banked_or_verified, 1 active, 17 matrix
rows, 11 finish rows, 15 Julia gate rows, 9 Julia capability rows`.
`git diff --check` was clean. The claim-boundary scan hit only quoted
forbidden phrases, guardrail text, historical boundary notes, or the scan
command itself.

## Tests Of The Tests

The DRM.jl focused test now rejects comparator rows outside
`gaussian_loconly_phylo_reml`. The drmTMB mission-control validator still
checks dashboard structure and the AI-REML coverage/readiness drift guards.

## Consistency Audit

The mission-control matrix remains partial for AI-REML-inspired simulation and
unsupported for bridge support. No external comparator dependency or optional
script is claimed.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on. The local issue draft was refreshed
but not posted.

## What Did Not Go Smoothly

Nothing material. The sync stayed to dashboard and evidence wording.

## Team Learning

Mission-control should mirror row-shaped evidence only after the implementation
repo has a validator for the row target. Here, the DRM.jl target validator
prevents q4 or generic LMM comparator rows from entering the exact-Gaussian
lane.

## Known Limitations

The external comparator remains planned. No package dependency, optional
developer script, interval coverage, bridge promotion, q4 promotion,
non-Gaussian claim, Ayumi-facing claim, or 10k-scale claim exists.

## Next Actions

Choose and fixture a same-estimand external comparator only in a separate
developer-only task.
