# Post-#602 Dashboard Truth Refresh

Date: 2026-06-17

## Goal

Refresh the mission-control dashboard and capability matrix after PR #602
merged the q8 staged diagnostic artifact. The main stale risks were old
`drmTMB#544` active/open wording and dashboard status text that predated the
q8 cold-vs-staged diagnostic artifact.

## What Changed

- Updated `docs/design/168-r-julia-finish-capability-matrix.md` so
  `drmTMB#544` is described as closed after the generated gate registry,
  capability comparison, docs-drift guard, and dashboard rendering landed.
- Replaced the old "First Work Order" with a post-#602 work order that treats
  the widget, native binomial first slice, bridge-gate guard, binomial
  comparator, binomial Wald interval artifact, and q8 staged diagnostic
  artifact as banked.
- Updated `docs/dev-log/dashboard/status.json` so the bridge capability row is
  banked, metrics match the new status counts, active-work text names the q8
  staged diagnostic artifact, and the ADEMP/comparator row points to the q8
  after-task note.
- Updated `docs/dev-log/dashboard/sweep.json` so the lightweight sweep summary
  includes the q8 staged diagnostic artifact and keeps q8 coverage/power
  planned.

## Checks

```sh
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json
python3 -m json.tool docs/dev-log/dashboard/sweep.json
rg -n '#544 remains|drmTMB#544 remains|staged in codex|Keep `drmTMB#544` open|Keep `drmTMB#544` active|Implement drmTMB#544|Start optional Phase 18|First Work Order' docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json docs/design/168-r-julia-finish-capability-matrix.md || true
git diff --check
```

The mission-control validator passed:

```text
mission_control_ok: 21/68 banked_or_verified, 3 active, 17 matrix rows, 11 finish rows, 15 Julia gate rows, 9 Julia capability rows
```

## Boundary

This is a status/dashboard truth-refresh slice only. It does not change R
package runtime code, likelihoods, `src/drmTMB.cpp`, Julia bridge gates,
DRM.jl code, Ayumi/Model A work, q8 recovery/coverage/power status, public
warm-start support, or release-readiness claims.
